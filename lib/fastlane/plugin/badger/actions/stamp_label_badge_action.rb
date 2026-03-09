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
        label     = params[:label]
        icon_glob = params[:icon_glob]

        UI.user_error!("label is required") if label.nil? || label.strip.empty?

        icons = Dir.glob(icon_glob)
        if icons.empty?
          UI.important("stamp_label_badge: no icons matched glob '#{icon_glob}'")
          return
        end

        UI.message("stamp_label_badge: '#{label}' → #{icons.count} icon(s)")

        icons.each do |icon|
          Helper::BadgerHelper.stamp_text(
            icon_path: icon,
            version:   nil,
            build:     nil,
            ticket:    label
          )
        end
      end

      def self.description
        "Stamps a single text badge onto app icons using ImageMagick"
      end

      def self.details
        [
          "Composites a full-orange text badge showing any label you provide",
          "(e.g. 'TKT-1234', 'PR-42', 'main') at the center of every icon",
          "matched by icon_glob. Use on its own or combine with",
          "stamp_version_badge to also show a version+build badge.",
          "No network access — pure ImageMagick via mini_magick.",
          "Requires the `magick` binary (ImageMagick 7+) in PATH."
        ].join("\n")
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key:         :label,
            env_name:    "BADGER_LABEL",
            description: "Text to display on the badge, e.g. 'TKT-1234' or 'PR-42'",
            optional:    false,
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
