require 'net/http'
require 'uri'
require 'json'

module DiscourseWemix
  class WemixController < ::ApplicationController
    requires_plugin DiscourseWemix::PLUGIN_NAME
    before_action :ensure_logged_in

    RET_OK ||= 0
    RET_NG ||= 1
    POINT_NOT_ENOUGH ||= 2
    ADDRESS_MISMATCH ||= 3
    TOKEN_NOT_ENOUGH ||= 4
    ALLOW_TOKEN_NOT_ENOUGH ||= 5

    def connect
      wemix_id = params.require(:wemix_id)
      wemix_address = params.require(:wemix_address)
      current_user.wemix_id = wemix_id
      current_user.wemix_address = wemix_address
      current_user.save
      render json: { code: RET_OK, message: "" }
    end

    def point_daily_reward
      DiscourseWemix::Activity.where(
        user: current_user,
        activity_type: DiscourseWemix::DAILY_REWARD,
        created_at: Time.zone.today.beginning_of_day..Time.zone.today.end_of_day
      ).first_or_create do |activity|
        activity.activity_type = DiscourseWemix::DAILY_REWARD
        activity.amount = SiteSetting.daily_reward_point
        activity.wemix_id = current_user.wemix_id
        activity.wemix_address = current_user.wemix_address
        activity.user = current_user

        current_user.point = current_user.point() + activity.amount
        current_user.save!
      end
    end

    def point
      # count = Activity::where(user_id: current_user.id(), pay_at: nil).sum(:amount)
      render json: { code: RET_OK, message: "", point: current_user.point() }
    end

    def binder_uri
      URI.parse SiteSetting.binder_url
    end

    def vks_uri
      URI.parse SiteSetting.vks_url
    end

    def http(uri)
      Net::HTTP.new(uri.host, uri.port).tap { |http| http.use_ssl = true }
    end

    def contract_address(contract = SiteSetting.wemix_ft)
      request = Net::HTTP::Post.new(binder_uri.request_uri)

      request.add_field 'Content-Type',
                        'application/json'
      request.body = {
        id:       '1',
        jsonrpc:  '2.0',
        method:   'contract_contractAddress',
        params:   [ SiteSetting.wemix_chain, contract ]
      }.to_json

      response = http(binder_uri).request(request)
      JSON.parse(response.body)['result']
    end

    def nonce(user_addr, contract = SiteSetting.wemix_ft)
      request = Net::HTTP::Post.new(binder_uri.request_uri)

      request.add_field 'Content-Type',
                        'application/json'
      request.body = {
        id:       '1',
        jsonrpc:  '2.0',
        method:   'contract_callContract',
        params:   [ SiteSetting.wemix_chain, contract, 'getNonce', [
          user_addr
        ]]
      }.to_json

      response = http(binder_uri).request(request)
      JSON.parse(response.body)['result']
    end

    def recover_message(message, signature)
      request = Net::HTTP::Post.new(binder_uri.request_uri)

      request.add_field 'Content-Type',
                        'application/json'
      request.body = {
        id:       '1',
        jsonrpc:  '2.0',
        method:   'contract_recoverMessage',
        params:   [ message, signature ]
      }.to_json

      response = http(binder_uri).request(request)
      JSON.parse(response.body)['result']
    end

    def keccak256(signature)
      request = Net::HTTP::Post.new(binder_uri.request_uri)

      request.add_field 'Content-Type',
                        'application/json'
      request.body = {
        id:       '1',
        jsonrpc:  '2.0',
        method:   'contract_keccak256',
        params:   [ signature ]
      }.to_json

      response = http(binder_uri).request(request)
      JSON.parse(response.body)['result']
    end

    def vks_sign_message(message)
      request = Net::HTTP::Post.new(vks_uri.request_uri)

      request.add_field 'Content-Type',
                        'application/json'
      request.add_field 'Authorization',
                        "Bearer #{SiteSetting.vks_credentials}"
      #
      # request.set_form_data 'grant_type' => 'client_credentials'
      #

      request.body = {
        id:       '1',
        jsonrpc:  '2.0',
        method:   'sign_signMessage',
        params:   [ message ]
      }.to_json

      response = http(vks_uri).request(request)
      JSON.parse(response.body)['result']
    end

    def do_exchange(signature, vks_signature)
      request = Net::HTTP::Post.new(binder_uri.request_uri)

      request.add_field 'Content-Type',
                        'application/json'
      request.body = {
        id:       '1',
        jsonrpc:  '2.0',
        method:   'tx_sendUnsignedTx',
        params:   [ SiteSetting.wemix_chain, SiteSetting.wemix_ft, "exchangeToToken",
                    [
                      session[:message][1][:value],
                      session[:message][2][:value],
                      session[:message][3][:value],
                      signature,
                      vks_signature
                    ]
        ]
      }.to_json

      response = http(binder_uri).request(request)
      JSON.parse(response.body)['result']
    end

    def point_tx
      return render json: { code: POINT_NOT_ENOUGH, message: I18n.t("wemix.point_not_enough")} if current_user.point < 1
      session[:contract] = contract_address
      session[:nonce] = nonce(current_user.wemix_address)[0]
      session[:message] = [
        {type: "address", value: session[:contract], name: "contract"},
        {type: "address", value: current_user.wemix_address, name: "user"},
        {type: "uint256", value: session[:nonce], name: "nonce"},
        {type: "uint256", value: current_user.point.to_s, name: "amount"},
      # {type: "address", value: "0x94444d3206cccb2e03fa9abc9722c533d26c21a5", name: "contract"},
      # {type: "address", value: "0x4818fb7d10639d7b42b4cdf7c022d901e7190c83", name: "user"},
      # {type: "uint256", value: "0", name: "nonce"},
      # {type: "uint256", value: current_user.point.to_s, name: "amount"},
      ]
      render json: {
        code:0,
        message: I18n.t("wemix.point_tx", count: current_user.point),
        data: [
          {
            message: session[:message],
            chain: SiteSetting.wemix_chain,
          }
        ]
      }
    end

    def exchange
      # :todo 锁定用户点数
      return render json: { code: POINT_NOT_ENOUGH, message: I18n.t("wemix.point_not_enough")} if current_user.point < session[:message][3][:value].to_i
      signature = params.require(:signature)
      user_address = recover_message(session[:message], signature)
      return render json: { code: ADDRESS_MISMATCH, message: I18n.t("wemix.address_mismatch")} if user_address != current_user.wemix_address
      vks_signature = vks_sign_message(keccak256(signature))
      result = do_exchange(signature, vks_signature)
      return render json: { code: RET_NG, message: I18n.t("wemix.server_error")} if result.nil?
      current_user.point = current_user.point() - session[:message][3][:value].to_i
      current_user.save
      render json: { code: RET_OK, data: result}
    end

    def balance(user_addr = current_user.wemix_address)
      request = Net::HTTP::Post.new(binder_uri.request_uri)

      request.add_field 'Content-Type',
                        'application/json'
      request.body = {
        id:       '1',
        jsonrpc:  '2.0',
        method:   'contract_callContract',
        params:   [ SiteSetting.wemix_chain, SiteSetting.wemix_ft, 'balanceOf', [
          user_addr
        ]]
      }.to_json

      response = http(binder_uri).request(request)
      JSON.parse(response.body)['result'][0].to_i
    end

    def unsign_approve(address, amount)
      request = Net::HTTP::Post.new(binder_uri.request_uri)

      request.add_field 'Content-Type',
                        'application/json'
      request.body = {
        id:       '1',
        jsonrpc:  '2.0',
        method:   'tx_makeUnsignedTx',
        params:   [ SiteSetting.wemix_chain, SiteSetting.wemix_ft, "approve",
                    [
                      address,
                      amount.to_s,
                    ],
                    current_user.wemix_address,
                    0
        ]
      }.to_json

      response = http(binder_uri).request(request)
      JSON.parse(response.body)['result']
    end

    def approve_tx
      return render json: { code: TOKEN_NOT_ENOUGH, message: I18n.t("wemix.token_not_enough")} if balance < SiteSetting.mint_fee
      approve_result = unsign_approve(contract_address(SiteSetting.wemix_nft), SiteSetting.mint_fee)
      session[:hash] = approve_result["hash"]
      session[:unsignedTx] = approve_result["unsignedTx"]
      render json: {
        code:0,
        message: I18n.t("wemix.nft_tx", count: SiteSetting.mint_fee),
        data: [ approve_result["hash"]]
      }
    end

    def recover_hash(hash, signature)
      request = Net::HTTP::Post.new(binder_uri.request_uri)

      request.add_field 'Content-Type',
                        'application/json'
      request.body = {
        id:       '1',
        jsonrpc:  '2.0',
        method:   'contract_recoverHash',
        params:   [ hash, signature ]
      }.to_json

      response = http(binder_uri).request(request)
      JSON.parse(response.body)['result']
    end

    def transfer(tx, signature)
      request = Net::HTTP::Post.new(binder_uri.request_uri)

      request.add_field 'Content-Type',
                        'application/json'
      request.body = {
        id:       '1',
        jsonrpc:  '2.0',
        method:   'tx_sendSignedTx',
        params:   [ SiteSetting.wemix_chain,
                    tx,
                    signature
        ]
      }.to_json

      response = http(binder_uri).request(request)
      JSON.parse(response.body)['result']
    end

    def allowance(user_addr, contract)
      request = Net::HTTP::Post.new(binder_uri.request_uri)

      request.add_field 'Content-Type',
                        'application/json'
      request.body = {
        id:       '1',
        jsonrpc:  '2.0',
        method:   'token_allowance',
        params:   [ SiteSetting.wemix_chain,
                    SiteSetting.wemix_ft,
                    user_addr,
                    contract
        ]
      }.to_json

      response = http(binder_uri).request(request)
      JSON.parse(response.body)['result']
    end

    def approve
      return render json: { code: TOKEN_NOT_ENOUGH, message: I18n.t("wemix.token_not_enough")} if balance < SiteSetting.mint_fee
      signature = params.require(:signature)
      user_address = recover_hash(session[:hash], signature)
      return render json: { code: ADDRESS_MISMATCH, message: I18n.t("wemix.address_mismatch")} if user_address != current_user.wemix_address
      transfer(session[:unsignedTx], signature)
      # todo: trans_result 验证
      allowance_token = allowance(current_user.wemix_address, contract_address(SiteSetting.wemix_nft)).to_i
      return render json: { code: ALLOW_TOKEN_NOT_ENOUGH, message: I18n.t("wemix.allow_token_not_enough")} if allowance_token < SiteSetting.mint_fee
      render json: { code: RET_OK }
    end

    def mint_tx
      allowance_token = allowance(current_user.wemix_address, contract_address(SiteSetting.wemix_nft)).to_i
      return render json: { code: ALLOW_TOKEN_NOT_ENOUGH, message: I18n.t("wemix.allow_token_not_enough")} if allowance_token < SiteSetting.mint_fee
      session[:contract] = contract_address(SiteSetting.wemix_nft)
      session[:nonce] = nonce(current_user.wemix_address, SiteSetting.wemix_nft)[0]
      message = [
        {type: "address", value: session[:contract], name: "contract"},
        {type: "uint", value: SiteSetting.mint_fee, name: "fee"},
        {type: "address", value: current_user.wemix_address, name: "user"},
        {type: "uint", value: session[:nonce], name: "nonce"},
        {type: "bool", value: false, name: "isTransferable"},
      ]
      session[:message] = [
        {type: "address", value: session[:contract], name: "contract"},
        {type: "uint", value: SiteSetting.mint_fee.to_s, name: "fee"},
        {type: "address", value: current_user.wemix_address, name: "user"},
        {type: "uint", value: session[:nonce].to_s, name: "nonce"},
        {type: "bool", value: "false", name: "isTransferable"},
      ]
      render json: {
        code:0,
        message: I18n.t("wemix.nft_tx", count: SiteSetting.mint_fee),
        data: [
          {
            message: message,
            chain: SiteSetting.wemix_chain,
          }
        ]
      }

    end

    def soliditySHA3(nft_json, signature)
      request = Net::HTTP::Post.new(binder_uri.request_uri)

      request.add_field 'Content-Type',
                        'application/json'
      request.body = {
        id:       '1',
        jsonrpc:  '2.0',
        method:   'contract_soliditySHA3',
        params:   [
          [
            {"type": "string", "value": nft_json},
            {"type": "bytes", "value": signature}
          ]
      ]
      }.to_json

      response = http(binder_uri).request(request)
      JSON.parse(response.body)['result']
    end

    def do_mint(signature, vks_signature)
      request = Net::HTTP::Post.new(binder_uri.request_uri)

      request.add_field 'Content-Type',
                        'application/json'
      request.body = {
        id:       '1',
        jsonrpc:  '2.0',
        method:   'tx_sendUnsignedTx',
        params:   [ SiteSetting.wemix_chain, SiteSetting.wemix_nft, "mint",
                    [
                      session[:message][1][:value],
                      session[:message][2][:value],
                      session[:message][3][:value],
                      session[:message][4][:value],
                      SiteSetting.nft_json,
                      signature,
                      vks_signature
                    ]
        ]
      }.to_json

      response = http(binder_uri).request(request)
      JSON.parse(response.body)['result']
    end

    def mint
      signature = params.require(:signature)
      user_address = recover_message(session[:message], signature)
      return render json: { code: ADDRESS_MISMATCH, message: I18n.t("wemix.address_mismatch")} if user_address != current_user.wemix_address
      vks_signature = vks_sign_message(soliditySHA3(SiteSetting.nft_json, signature))
      render json: { code: RET_OK, data: do_mint(signature, vks_signature)}
    end

    def user_nft
      request = Net::HTTP::Post.new(binder_uri.request_uri)

      request.add_field 'Content-Type',
                        'application/json'
      request.body = {
        id:       '1',
        jsonrpc:  '2.0',
        method:   'token_tokensOfOwner',
        params:   [ SiteSetting.wemix_chain, SiteSetting.wemix_nft, current_user.wemix_address]
      }.to_json

      response = http(binder_uri).request(request)

      render json: { code: RET_OK, data: JSON.parse(response.body)['result']}
    end

    def nft_uri
      token_id = params.require(:token_id)
      request = Net::HTTP::Post.new(binder_uri.request_uri)

      request.add_field 'Content-Type',
                        'application/json'
      request.body = {
        id:       '1',
        jsonrpc:  '2.0',
        method:   'token_tokenURI',
        params:   [ SiteSetting.wemix_chain, SiteSetting.wemix_nft, token_id.to_i]
      }.to_json

      response = http(binder_uri).request(request)

      render json: { code: RET_OK, data: JSON.parse(response.body)['result']}
    end

    def index
      # post_id = params.require(:post_id)
      # poll_name = params.require(:poll_name)
      # options = params.require(:options)
      # users = { id:1, nickname: SiteSetting.wemix_client_id, age: 22 }
      # render json: users
      # render json: MultiJson.dump(params)
      render_json_error "hello"
      begin
        # poll, options = DiscoursePoll::Poll.vote(current_user, post_id, poll_name, options)
        # render json: { hello: world }
      rescue DiscourseWemix::Error => e
        render_json_error e.message
      end
    end
  end
end
