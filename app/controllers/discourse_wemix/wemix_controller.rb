require 'net/http'
require 'uri'
require 'json'

module DiscourseWemix
  class WemixController < ::ApplicationController
    requires_plugin DiscourseWemix::PLUGIN_NAME
    before_action :ensure_logged_in

    SUCCESS ||= 0
    POINT_NOT_ENOUGH ||= 1
    ADDRESS_MISMATCH ||= 2

    def connect
      wemix_id = params.require(:wemix_id)
      wemix_address = params.require(:wemix_address)
      current_user.wemix_id = wemix_id
      current_user.wemix_address = wemix_address
      current_user.save
      render json: { code: SUCCESS, message: "" }
    end

    def point
      # count = Activity::where(user_id: current_user.id(), pay_at: nil).sum(:amount)
      render json: { code: SUCCESS, message: "", point: current_user.point() }
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

    def contract_address
      request = Net::HTTP::Post.new(binder_uri.request_uri)

      request.add_field 'Content-Type',
                        'application/json'
      request.body = {
        id:       '1',
        jsonrpc:  '2.0',
        method:   'contract_contractAddress',
        params:   [ SiteSetting.wemix_chain, SiteSetting.wemix_token ]
      }.to_json

      response = http(binder_uri).request(request)
      JSON.parse(response.body)['result']
    end

    def nonce(user_addr)
      request = Net::HTTP::Post.new(binder_uri.request_uri)

      request.add_field 'Content-Type',
                        'application/json'
      request.body = {
        id:       '1',
        jsonrpc:  '2.0',
        method:   'contract_callContract',
        params:   [ SiteSetting.wemix_chain, SiteSetting.wemix_token, 'getNonce', [
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

    def vks_sign_message(sign_keccak256)
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
        params:   [ sign_keccak256 ]
      }.to_json

      response = http(vks_uri).request(request)
      JSON.parse(response.body)['result']
    end

    def exchange_to_token(signature, vks_signature)
      request = Net::HTTP::Post.new(binder_uri.request_uri)

      request.add_field 'Content-Type',
                        'application/json'
      request.body = {
        id:       '1',
        jsonrpc:  '2.0',
        method:   'tx_sendUnsignedTx',
        params:   [ SiteSetting.wemix_chain, SiteSetting.wemix_token, "exchangeToToken",
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
      return render json: { code: POINT_NOT_ENOUGH, message: I18n.t("wemix.point_not_enough")} if current_user.point < 1
      signature = params.require(:signature)
      user_address = recover_message(session[:message], signature)
      return render json: { code: ADDRESS_MISMATCH, message: I18n.t("wemix.address_mismatch")} if user_address != current_user.wemix_address
      vks_signature = vks_sign_message(keccak256(signature))
      render json: { code: SUCCESS, message: exchange_to_token(signature, vks_signature)}
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
