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
