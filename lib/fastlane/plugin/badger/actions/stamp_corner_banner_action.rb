# badger — fastlane-plugin-badger
# stamp_corner_banner_action.rb
#
# Created by Richard P. Ulivella on 09 Mar 2026.
# Copyright © 2026 Richard P. Ulivella. All rights reserved.

require "fastlane/plugin/badger/helper/badger_helper"

module Fastlane
  module Actions
    class StampCornerBannerAction < Action
      VALID_CORNERS = %w[bottom_right bottom_left top_right top_left].freeze
      VALID_STYLES  = %w[dark light].freeze
      VALID_SIZES   = %w[normal large].freeze

      def self.run(params)
        label     = params[:label]
        corner    = params[:corner]
        style     = params[:style]
        size      = params[:size]
        icon_glob = params[:icon_glob]

        UI.user_error!("label is required") if label.nil? || label.strip.empty?
        UI.user_error!("corner must be one of: #{VALID_CORNERS.join(', ')}") unless VALID_CORNERS.include?(corner)
        UI.user_error!("style must be one of: #{VALID_STYLES.join(', ')}") unless VALID_STYLES.include?(style)
        UI.user_error!("size must be one of: #{VALID_SIZES.join(', ')}") unless VALID_SIZES.include?(size)

        icons = Dir.glob(icon_glob)
        if icons.empty?
          UI.important("stamp_corner_banner: no icons matched glob '#{icon_glob}'")
          return
        end

        UI.message("stamp_corner_banner: '#{label}' #{corner}/#{style}/#{size} → #{icons.count} icon(s)")

        icons.each do |icon|
          Helper::BadgerHelper.stamp_corner_banner(
            icon_path: icon,
            label:     label,
            corner:    corner.to_sym,
            style:     style.to_sym,
            size:      size.to_sym
          )
        end
      end

      def self.description
        "Stamps a diagonal corner ribbon banner onto app icons using ImageMagick"
      end

      def self.details
        [
          "Generates a diagonal corner ribbon (e.g. 'ALPHA', 'BETA', 'NDA') and",
          "composites it over every icon matched by icon_glob.",
          "The ribbon runs edge-to-edge — the canvas clips it naturally.",
          "Uses Figtree Black with a knockout text effect and drop shadow.",
          "No network access — pure ImageMagick via mini_magick.",
          "Requires the `magick` binary (ImageMagick 7+) in PATH.",
          "",
          "size: :normal  — ribbon height is 14% of icon (ALPHA, BETA, PREVIEW)",
          "size: :large   — ribbon height is 17% of icon (NDA, short labels)"
        ].join("\n")
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key:         :label,
            env_name:    "BADGER_LABEL",
            description: "Text for the corner ribbon, e.g. 'ALPHA', 'NDA'. " \
                         "Automatically uppercased",
            optional:    false,
            type:        String
          ),
          FastlaneCore::ConfigItem.new(
            key:           :corner,
            env_name:      "BADGER_CORNER",
            description:   "Corner to place the ribbon: bottom_right, bottom_left, " \
                           "top_right, top_left",
            default_value: "bottom_right",
            optional:      true,
            type:          String
          ),
          FastlaneCore::ConfigItem.new(
            key:           :style,
            env_name:      "BADGER_STYLE",
            description:   "Ribbon style: dark (#1c1c1e bg, white text) or " \
                           "light (#efefef bg, dark text)",
            default_value: "dark",
            optional:      true,
            type:          String
          ),
          FastlaneCore::ConfigItem.new(
            key:           :size,
            env_name:      "BADGER_SIZE",
            description:   "Ribbon size: normal (14% of icon) or large (17% of icon). " \
                           "Use large for short labels like 'NDA'",
            default_value: "normal",
            optional:      true,
            type:          String
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
