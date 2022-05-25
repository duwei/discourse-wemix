require 'net/http'
require 'uri'
require 'json'

module DiscourseWemix
  class WemixController < ::ApplicationController
    requires_plugin DiscourseWemix::PLUGIN_NAME
    before_action :ensure_logged_in

    def connect
      wemix_id = params.require(:wemix_id)
      wemix_address = params.require(:wemix_address)
      current_user.wemix_id = wemix_id
      current_user.wemix_address = wemix_address
      current_user.save
      render json: { code:0, message: "" }
    end

    def point
      # count = Activity::where(user_id: current_user.id(), pay_at: nil).sum(:amount)
      render json: { code:0, message: "", point: current_user.point() }
    end

    def binder_uri
      URI.parse SiteSetting.binder_url
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

    def point_tx
      user_address = current_user.wemix_address
      render json: { code:0, message: "", data:
        [{
           message:[
             {type: "address", value: contract_address, name: "contract"},
             {type: "address", value: user_address, name: "user"},
             {type: "uint256", value: nonce(user_address)[0], name: "nonce"},
             {type: "uint256", value: current_user.point, name: "amount"},
           ],
           chain: SiteSetting.wemix_chain
         }]
      }
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
