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
  end

  Discourse::Application.routes.append do
    mount ::DiscourseWemix::Engine, at: "/wemix"
  end
end
