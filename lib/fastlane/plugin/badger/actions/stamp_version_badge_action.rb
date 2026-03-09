require "fastlane/plugin/badger/helper/badger_helper"

module Fastlane
  module Actions
    class StampVersionBadgeAction < Action
      def self.run(params)
        version   = params[:version]
        build     = params[:build]
        icon_glob = params[:icon_glob]

        # Auto-read version/build from xcodeproj if not provided explicitly
        if (version.nil? || build.nil?) && params[:xcodeproj]
          require "xcodeproj"
          proj = Xcodeproj::Project.open(params[:xcodeproj])
          target = proj.targets.first
          config = target.build_configurations.find { |c| c.name == "Release" } ||
                   target.build_configurations.first
          version ||= config.build_settings["MARKETING_VERSION"] ||
                      config.build_settings["CFBundleShortVersionString"]
          build   ||= config.build_settings["CURRENT_PROJECT_VERSION"] ||
                      config.build_settings["CFBundleVersion"]
        end

        UI.user_error!("version is required") if version.nil? || version.strip.empty?
        UI.user_error!("build is required")   if build.nil?   || build.to_s.strip.empty?

        icons = Dir.glob(icon_glob)
        if icons.empty?
          UI.important("stamp_version_badge: no icons matched glob '#{icon_glob}'")
          return
        end

        UI.message("stamp_version_badge: #{version} (#{build}) → #{icons.count} icon(s)")

        icons.each do |icon|
          Helper::BadgerHelper.stamp_text(
            icon_path: icon,
            version:   version.to_s,
            build:     build.to_s
          )
        end
      end

      def self.description
        "Stamps a local version+build text badge onto app icons using ImageMagick"
      end

      def self.details
        [
          "Generates a two-tone text badge (gray | orange) with the version and build number",
          "and composites it at the top of every icon matched by icon_glob.",
          "No network access, no shields.io — pure ImageMagick via mini_magick.",
          "Requires the `magick` binary (ImageMagick 7+) in PATH."
        ].join("\n")
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key:         :xcodeproj,
            env_name:    "BADGER_XCODEPROJ",
            description: "Path to the .xcodeproj file. Used to auto-read version/build " \
                         "when version or build params are not provided",
            optional:    true,
            type:        String
          ),
          FastlaneCore::ConfigItem.new(
            key:         :version,
            env_name:    "BADGER_VERSION",
            description: "App version string, e.g. '1.5.2'. " \
                         "Overrides the value read from xcodeproj",
            optional:    true,
            type:        String
          ),
          FastlaneCore::ConfigItem.new(
            key:         :build,
            env_name:    "BADGER_BUILD",
            description: "Build number string, e.g. '1234'. " \
                         "Overrides the value read from xcodeproj",
            optional:    true,
            type:        String
          ),
          FastlaneCore::ConfigItem.new(
            key:            :icon_glob,
            env_name:       "BADGER_ICON_GLOB",
            description:    "Glob pattern to discover icon PNG files",
            default_value:  "**/AppIcon.appiconset/*.png",
            optional:       true,
            type:           String
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
