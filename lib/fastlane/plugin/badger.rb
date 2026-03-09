# badger — fastlane-plugin-badger
# badger.rb
#
# Created by Richard P. Ulivella on 09 Mar 2026.
# Copyright © 2026 Richard P. Ulivella. All rights reserved.

require "fastlane/plugin/badger/version"
require "fastlane/plugin/badger/helper/badger_helper"
require "fastlane/plugin/badger/actions/stamp_version_badge_action"
require "fastlane/plugin/badger/actions/stamp_label_badge_action"
require "fastlane/plugin/badger/actions/stamp_corner_banner_action"

module Fastlane
  module Badger
    # Return all .rb files inside the "actions" and "helper" directory
    def self.all_classes
      Dir[File.expand_path("**/{actions,helper}/*.rb", File.dirname(__FILE__))]
    end
  end
end
