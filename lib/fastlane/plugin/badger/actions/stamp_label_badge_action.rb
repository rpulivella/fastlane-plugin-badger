# badger — fastlane-plugin-badger
# stamp_label_badge_action.rb
#
# Created by Richard P. Ulivella on 09 Mar 2026.
# Copyright © 2026 Richard P. Ulivella. All rights reserved.

require "fastlane/plugin/badger/helper/badger_helper"

module Fastlane
  module Actions
    class StampLabelBadgeAction < Action
      def self.run(params)
        north_left  = params[:north_left]
        north_right = params[:north_right]
        icon_glob   = params[:icon_glob]

        if (north_left.nil? || north_left.strip.empty?) &&
           (north_right.nil? || north_right.strip.empty?)
          UI.user_error!("At least one of north_left or north_right is required")
        end

        icons = Dir.glob(icon_glob)
        if icons.empty?
          UI.important("stamp_label_badge: no icons matched glob '#{icon_glob}'")
          return
        end

        left_display  = north_left  ? "'#{north_left}'"  : "(none)"
        right_display = north_right ? "'#{north_right}'" : "(none)"
        UI.message("stamp_label_badge: #{left_display} | #{right_display} → #{icons.count} icon(s)")

        icons.each do |icon|
          Helper::BadgerHelper.stamp_text(
            icon_path:   icon,
            north_left:  north_left,
            north_right: north_right
          )
        end
      end

      def self.description
        "Stamps a North-slot text badge onto app icons using ImageMagick"
      end

      def self.details
        [
          "Composites a two-sub-slot horizontal badge at the top (North) of every icon",
          "matched by icon_glob.",
          "  north_left  → grey (#555555) segment on the left",
          "  north_right → orange (#fe7d37) segment on the right",
          "Either sub-slot is optional; providing only one renders a single-color badge.",
          "No network access — pure ImageMagick via mini_magick.",
          "Requires the `magick` binary (ImageMagick 7+) in PATH."
        ].join("\n")
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key:         :north_left,
            env_name:    "BADGER_NORTH_LEFT",
            description: "Grey left segment text for the North badge, e.g. 'LIG-'",
            optional:    true,
            type:        String
          ),
          FastlaneCore::ConfigItem.new(
            key:         :north_right,
            env_name:    "BADGER_NORTH_RIGHT",
            description: "Orange right segment text for the North badge, e.g. '2969'",
            optional:    true,
            type:        String
          ),
          FastlaneCore::ConfigItem.new(
            key:           :icon_glob,
            env_name:      "BADGER_ICON_GLOB",
            description:   "Glob pattern to discover icon PNG files",
            default_value: "**/AppIcon.appiconset/*.png",
            optional:      true,
            type:          String
          )
        ]
      end

      def self.authors
        ["rpulivella"]
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end
    end
  end
end
