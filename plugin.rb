# frozen_string_literal: true

# name: discourse-wemix
# about: Wemix Discourse plugin
# version: 0.0.1
# authors: Discourse
# url: https://github.com/duwei/discourse-wemix.git
# required_version: 2.7.0
# transpile_js: true

enabled_site_setting :wemix_enabled

register_svg_icon "wallet" if respond_to?(:register_svg_icon)

after_initialize do
end
