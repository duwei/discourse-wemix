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
register_svg_icon "wallet"
register_svg_icon "dollar-sign"
register_svg_icon "file-invoice-dollar"

extend_content_security_policy(
  script_src: ['https://storage.cloud.google.com/wemix/wemix.js'],
  object_src: []
)

after_initialize do
  module ::DiscourseWemix
    PLUGIN_NAME ||= "discourse_wemix"
    POINT_TYPE_TOPIC ||= 1
    POINT_TYPE_POST ||= 2
    POINT_TYPE_TOKEN ||= 3
    DAILY_REWARD ||= 4

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
    get "/point/daily_reward" => 'wemix#point_daily_reward'
    get "/point" => 'wemix#point'
    post "/point/tx" => 'wemix#point_tx'
    post "/exchange" => 'wemix#exchange'
    post "/nft/approve_tx" => 'wemix#approve_tx'
    post "/nft/approve" => 'wemix#approve'
    post "/nft/mint_tx" => 'wemix#mint_tx'
    post "/nft/mint" => 'wemix#mint'
    get "/nft/list" => 'wemix#user_nft'
    post "/nft/uri" => 'wemix#nft_uri'
  end

  Discourse::Application.routes.append do
    mount ::DiscourseWemix::Engine, at: "/wemix"
  end

  def update_point(point_type, amount, user)
    activity = DiscourseWemix::Activity.new(
      activity_type: point_type,
      amount: amount,
      wemix_id: user.wemix_id,
      wemix_address: user.wemix_address,
      )
    activity.user = user
    activity.save!
    user.point = user.point() + amount
    user.save!
  end

  DiscourseEvent.on(:user_logged_in) do |user|
    # DiscourseWemix::Activity.where(
    #   user: user,
    #   activity_type: DiscourseWemix::DAILY_REWARD,
    #   created_at: Time.zone.today.beginning_of_day..Time.zone.today.end_of_day
    # ).first_or_create do |activity|
    #   activity.activity_type = DiscourseWemix::DAILY_REWARD
    #   activity.amount = SiteSetting.daily_reward_point
    #   activity.wemix_id = user.wemix_id
    #   activity.wemix_address = user.wemix_address
    #   activity.user = user
    #
    #   user.point = user.point() + activity.amount
    #   user.save!
    # end
  end

  DiscourseEvent.on(:topic_created) do |topic, _opts, user|
    update_point(DiscourseWemix::POINT_TYPE_TOPIC, SiteSetting.topic_point, user)
  end

  DiscourseEvent.on(:post_created) do |post, _opts, user|
    if post.post_number() > 1
      update_point(DiscourseWemix::POINT_TYPE_POST, SiteSetting.post_point, user)
    end
  end

  # require_dependency 'current_user_serializer'
  # class ::CurrentUserSerializer
  #   attributes :point
  #
  #   def point
  #     DiscourseWemix::Activity::where(user_id: object.id(), pay_at: nil).sum(:amount)
  #   end
  # end

  # load File.expand_path('../config/routes.rb', __FILE__)
end
