# frozen_string_literal: true

# name: discourse-wemix
# about: Wemix Discourse plugin
# version: 0.0.1
# authors: Discourse
# url: https://github.com/duwei/discourse-wemix.git
# required_version: 2.7.0
# transpile_js: true

enabled_site_setting :wemix_enabled

register_asset "stylesheets/common.scss"
register_svg_icon "wallet" if respond_to?(:register_svg_icon)

after_initialize do
  module ::DiscourseWemix
    PLUGIN_NAME ||= "discourse_wemix"
    POINT_TYPE_TOPIC ||= 1
    POINT_TYPE_POST ||= 2
    POINT_TYPE_TOKEN ||= 3

    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace DiscourseWemix
    end

    class Error < StandardError; end
  end

  require_relative "app/controllers/discourse_wemix/wemix_controller.rb"
  require_relative "app/models/discourse_wemix/activity.rb"

  DiscourseWemix::Engine.routes.draw do
    put "/connect" => 'wemix#connect'
    get "/point" => 'wemix#point'
  end

  Discourse::Application.routes.append do
    mount ::DiscourseWemix::Engine, at: "/wemix"
  end

  DiscourseEvent.on(:topic_created) do |topic, _opts, user|
    activity = DiscourseWemix::Activity.new(
      activity_type: DiscourseWemix::POINT_TYPE_TOPIC,
      amount: SiteSetting.topic_point,
    )
    activity.user = user
    activity.save()
  end

  DiscourseEvent.on(:post_created) do |post, _opts, user|
    if post.post_number() > 1
      activity = DiscourseWemix::Activity.new(
        activity_type: DiscourseWemix::POINT_TYPE_POST,
        amount: SiteSetting.post_point,
        )
      activity.user = user
      activity.save()
    end
  end

  require_dependency 'current_user_serializer'
  class ::CurrentUserSerializer
    attributes :point

    def point
      DiscourseWemix::Activity::where(user_id: object.id(), pay_at: nil).sum(:amount)
    end
  end

  # load File.expand_path('../config/routes.rb', __FILE__)
end
