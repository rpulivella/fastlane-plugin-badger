# badger — fastlane-plugin-badger
# badger_helper.rb
#
# Created by Richard P. Ulivella on 09 Mar 2026.
# Copyright © 2026 Richard P. Ulivella. All rights reserved.

require "mini_magick"
require "tmpdir"
require "fileutils"
require "securerandom"

module Fastlane
  module Helper
    module BadgerHelper
      # ────────────────────────────────────────────────────────────────────────
      # Font paths — resolved relative to the gem's assets/fonts/ directory.
      # Both fonts are bundled under OFL (SIL Open Font License).
      # ────────────────────────────────────────────────────────────────────────
      FONTS_DIR      = File.expand_path("../../../../../../assets/fonts", __FILE__)
      JETBRAINS_FONT = File.join(FONTS_DIR, "JetBrainsMonoNL-Bold.ttf")
      FIGTREE_FONT   = File.join(FONTS_DIR, "Figtree-Black.otf")

      # Typed value object for per-corner ribbon configuration.
      #   angle — ImageMagick rotation in degrees (positive = clockwise)
      #   cx, cy — ribbon center as a fraction of icon size
      CornerConfig = Data.define(:angle, :cx, :cy)

      CORNER_CFG = {
        bottom_right: CornerConfig.new(angle: -45, cx: 0.75, cy: 0.75),
        bottom_left:  CornerConfig.new(angle:  45, cx: 0.25, cy: 0.75),
        top_right:    CornerConfig.new(angle:  45, cx: 0.75, cy: 0.25),
        top_left:     CornerConfig.new(angle: -45, cx: 0.25, cy: 0.25)
      }.freeze

      DARK_BG    = "#1c1c1e"
      LIGHT_BG   = "#efefef"

      GREY_COLOR   = "#555555"
      ORANGE_COLOR = "#fe7d37"

      # ────────────────────────────────────────────────────────────────────────
      # Public API
      # ────────────────────────────────────────────────────────────────────────

      # Stamps text badges onto app icons using a two-slot layout:
      #
      # North slot  — horizontal two-tone bar at the top of the icon.
      #   north_left  → grey (#555555) segment on the left
      #   north_right → orange (#fe7d37) segment on the right
      #   Either sub-slot is optional; providing only one renders a single-color badge.
      #
      # Center slot — vertical two-tone stack in the middle of the icon.
      #   center_top    → grey (#555555) segment on top
      #   center_bottom → orange (#fe7d37) segment on bottom
      #   Either sub-slot is optional; providing only one renders a single-color badge.
      #
      # @param icon_path    [String] Path to a single PNG or xcassets directory.
      # @param north_left   [String, nil] Grey left segment text for North slot.
      # @param north_right  [String, nil] Orange right segment text for North slot.
      # @param center_top   [String, nil] Grey top segment text for Center slot.
      # @param center_bottom [String, nil] Orange bottom segment text for Center slot.
      def self.stamp_text(icon_path:,
                          north_left: nil, north_right: nil,
                          center_top: nil, center_bottom: nil)
        icons = resolve_icons(icon_path)
        UI.user_error!("No PNG icons found at: #{icon_path}") if icons.empty?

        validate_font!(JETBRAINS_FONT, "JetBrainsMonoNL-Bold.ttf")

        icons.each do |icon|
          UI.message("  badger stamp_text → #{icon}")

          # North slot — pointsize 90, border 18x9
          if north_left && north_right
            badge = tmp_file("north_badge", ".png")
            generate_horizontal_badge(north_left, north_right, badge, pointsize: 90, border: "18x9")
            round_corners(badge, radius: 4)
            composite_badge(icon, badge, "North")
            FileUtils.rm_f(badge)
          elsif north_right
            badge = tmp_file("north_badge", ".png")
            generate_single_badge(north_right, badge, color: ORANGE_COLOR, pointsize: 90, border: "18x9")
            round_corners(badge, radius: 4)
            composite_badge(icon, badge, "North")
            FileUtils.rm_f(badge)
          elsif north_left
            badge = tmp_file("north_badge", ".png")
            generate_single_badge(north_left, badge, color: GREY_COLOR, pointsize: 90, border: "18x9")
            round_corners(badge, radius: 4)
            composite_badge(icon, badge, "North")
            FileUtils.rm_f(badge)
          end

          # Center slot — pointsize 117, border 23x12 (1.3× North)
          if center_top && center_bottom
            badge = tmp_file("center_badge", ".png")
            generate_vertical_badge(center_top, center_bottom, badge, pointsize: 117, border: "23x12")
            round_corners(badge, radius: 4)
            composite_badge(icon, badge, "Center")
            FileUtils.rm_f(badge)
          elsif center_bottom
            badge = tmp_file("center_badge", ".png")
            generate_single_badge(center_bottom, badge, color: ORANGE_COLOR, pointsize: 117, border: "23x12")
            round_corners(badge, radius: 4)
            composite_badge(icon, badge, "Center")
            FileUtils.rm_f(badge)
          elsif center_top
            badge = tmp_file("center_badge", ".png")
            generate_single_badge(center_top, badge, color: GREY_COLOR, pointsize: 117, border: "23x12")
            round_corners(badge, radius: 4)
            composite_badge(icon, badge, "Center")
            FileUtils.rm_f(badge)
          end
        end
      end

      # Stamps a diagonal corner ribbon banner onto one or more icons.
      #
      # @param icon_path [String]  Path to a single PNG or xcassets directory.
      # @param label     [String]  Text for the banner, e.g. "ALPHA", "NDA".
      #   The label is automatically uppercased.
      # @param corner    [Symbol]  :bottom_right (default), :bottom_left,
      #   :top_right, :top_left
      # @param style     [Symbol]  :dark  (#1c1c1e bg, white 72% text — default)
      #                            :light (#efefef bg, dark 72% text)
      # @param size      [Symbol]  :normal (ribbon = 14% of icon — default)
      #                            :large  (ribbon = 17% of icon, suited for
      #                            short labels like "NDA" on NDA builds)
      def self.stamp_corner_banner(icon_path:, label:, corner: :bottom_right,
                                   style: :dark, size: :normal)
        icons = resolve_icons(icon_path)
        UI.user_error!("No PNG icons found at: #{icon_path}") if icons.empty?

        validate_font!(FIGTREE_FONT, "Figtree-Black.otf")

        corner_sym = corner.to_sym
        style_sym  = style.to_sym
        size_sym   = size.to_sym

        UI.user_error!("Unknown corner: #{corner}") unless CORNER_CFG.key?(corner_sym)

        icons.each do |icon|
          UI.message("  badger stamp_corner_banner → #{icon}")

          image      = MiniMagick::Image.open(icon)
          icon_size  = [image.width, image.height].min

          banner_path = tmp_file("banner", ".png")
          generate_corner_banner(
            label, banner_path,
            corner:    corner_sym,
            style:     style_sym,
            size:      size_sym,
            icon_size: icon_size
          )

          composite_corner_banner(icon, banner_path)
          FileUtils.rm_f(banner_path)
        end
      end

      # ────────────────────────────────────────────────────────────────────────
      # Icon discovery
      # ────────────────────────────────────────────────────────────────────────

      # Resolves icon_path to an array of absolute PNG paths.
      # Accepts:
      #   - A direct path to a single .png file
      #   - A path to an .xcassets directory → auto-discovers all PNGs inside
      #     any AppIcon.appiconset/ subdirectory
      #   - A path to an AppIcon.appiconset/ directory directly
      def self.resolve_icons(icon_path)
        path = File.expand_path(icon_path)

        case path
        in _ if File.file?(path) && path.end_with?(".png")
          [path]
        in _ if File.directory?(path) && path.end_with?(".appiconset")
          Dir.glob(File.join(path, "*.png")).sort
        in _ if File.directory?(path)
          pngs = Dir.glob(File.join(path, "**/AppIcon.appiconset/*.png")).sort
          pngs.empty? ? Dir.glob(File.join(path, "**/*.png")).sort : pngs
        else
          []
        end
      end

      # ────────────────────────────────────────────────────────────────────────
      # Badge generation helpers
      # ────────────────────────────────────────────────────────────────────────

      # Generates a single-color badge PNG for one sub-slot.
      #
      # @param label     [String]  Text to render.
      # @param out_path  [String]  Destination PNG path.
      # @param color     [String]  Background color (default: orange).
      # @param pointsize [Integer] Font point size.
      # @param border    [String]  ImageMagick border geometry, e.g. "9x5".
      def self.generate_single_badge(label, out_path,
                                     color: ORANGE_COLOR,
                                     pointsize: 90, border: "18x9")
        MiniMagick::Tool::Convert.new do |c|
          c.background color
          c.fill "white"
          c.font JETBRAINS_FONT
          c.pointsize pointsize.to_s
          c.gravity "Center"
          c << "label:#{label}"
          c.bordercolor color
          c.border border
          c << out_path
        end
      end

      # Generates a horizontal two-tone badge PNG for the North slot.
      # Left segment is grey, right segment is orange. Joined with +append.
      #
      # @param left_label  [String] Text for the grey left segment.
      # @param right_label [String] Text for the orange right segment.
      # @param out_path    [String] Destination PNG path.
      # @param left_color  [String] Background color for left segment.
      # @param right_color [String] Background color for right segment.
      # @param pointsize   [Integer] Font point size.
      # @param border      [String] ImageMagick border geometry, e.g. "9x5".
      def self.generate_horizontal_badge(left_label, right_label, out_path,
                                         left_color: GREY_COLOR, right_color: ORANGE_COLOR,
                                         pointsize: 90, border: "18x9")
        left_path  = "#{out_path}.left.png"
        right_path = "#{out_path}.right.png"

        [[left_path, left_color, left_label],
         [right_path, right_color, right_label]].each do |path, color, text|
          MiniMagick::Tool::Convert.new do |c|
            c.background color
            c.fill "white"
            c.font JETBRAINS_FONT
            c.pointsize pointsize.to_s
            c.gravity "Center"
            c << "label:#{text}"
            c.bordercolor color
            c.border border
            c << path
          end
        end

        MiniMagick::Tool::Convert.new do |c|
          c << left_path
          c << right_path
          c << "+append"
          c << out_path
        end

        FileUtils.rm_f([left_path, right_path])
      end

      # Generates a vertical two-tone badge PNG for the Center slot.
      # Top segment is grey, bottom segment is orange. Joined with -append.
      #
      # @param top_label    [String] Text for the grey top segment.
      # @param bottom_label [String] Text for the orange bottom segment.
      # @param out_path     [String] Destination PNG path.
      # @param top_color    [String] Background color for top segment.
      # @param bottom_color [String] Background color for bottom segment.
      # @param pointsize    [Integer] Font point size.
      # @param border       [String] ImageMagick border geometry, e.g. "9x5".
      def self.generate_vertical_badge(top_label, bottom_label, out_path,
                                       top_color: GREY_COLOR, bottom_color: ORANGE_COLOR,
                                       pointsize: 90, border: "18x9")
        top_path    = "#{out_path}.top.png"
        bottom_path = "#{out_path}.bottom.png"

        [[top_path, top_color, top_label],
         [bottom_path, bottom_color, bottom_label]].each do |path, color, text|
          MiniMagick::Tool::Convert.new do |c|
            c.background color
            c.fill "white"
            c.font JETBRAINS_FONT
            c.pointsize pointsize.to_s
            c.gravity "Center"
            c << "label:#{text}"
            c.bordercolor color
            c.border border
            c << path
          end
        end

        # Normalize both segments to the same width before stacking.
        # label: auto-sizes each canvas to its text, so segments can differ in width.
        # Extend the narrower one with its own background color, gravity Center,
        # so the text stays centered within the equalized block.
        top_w    = MiniMagick::Image.open(top_path).width
        bottom_w = MiniMagick::Image.open(bottom_path).width
        max_w    = [top_w, bottom_w].max

        [[top_path, top_color], [bottom_path, bottom_color]].each do |path, color|
          img = MiniMagick::Image.open(path)
          next if img.width == max_w
          system(
            "magick", path,
            "-gravity", "Center",
            "-background", color,
            "-extent", "#{max_w}x#{img.height}",
            path
          )
        end

        MiniMagick::Tool::Convert.new do |c|
          c << top_path
          c << bottom_path
          c << "-append"
          c << out_path
        end

        FileUtils.rm_f([top_path, bottom_path])
      end

      # Clips an image to rounded corners using DstIn compositing.
      # Passes arguments as an array to system() to avoid shell quoting issues
      # with parentheses.
      #
      # @param image_path [String] Path to the PNG to modify in-place.
      # @param radius     [Integer] Corner radius in pixels.
      def self.round_corners(image_path, radius: 4)
        image = MiniMagick::Image.open(image_path)
        w = image.width - 1
        h = image.height - 1
        tmp = "#{image_path}.rounded.png"

        system(
          "magick", image_path, "-alpha", "set",
          "(", "+clone", "-alpha", "transparent",
               "-fill", "white",
               "-draw", "roundrectangle 0,0 #{w},#{h} #{radius},#{radius}",
          ")", "-compose", "DstIn", "-composite",
          tmp
        )

        FileUtils.mv(tmp, image_path)
      end

      # Composites a badge PNG onto an icon PNG in-place at its natural size.
      # Badge dimensions are driven entirely by the pointsize used when generating
      # each segment — no resizing is applied. This ensures North and Center slots
      # share the same text height, since all segments use the same pointsize.
      #
      # @param icon_path  [String]  Path to the icon PNG (modified in-place).
      # @param badge_path [String]  Path to the badge PNG.
      # @param gravity    [String]  ImageMagick gravity, e.g. "North", "Center".
      def self.composite_badge(icon_path, badge_path, gravity)
        icon  = MiniMagick::Image.open(icon_path)
        badge = MiniMagick::Image.open(badge_path)

        result = icon.composite(badge) do |c|
          c.compose "Over"
          c.gravity gravity
        end

        result.write(icon_path)
      end

      # ────────────────────────────────────────────────────────────────────────
      # Corner banner helpers
      # ────────────────────────────────────────────────────────────────────────

      # Generates a canvas-sized transparent PNG with the diagonal ribbon
      # already composited at the configured corner position.
      # The ribbon rectangle is wider than the canvas diagonal so it clips
      # naturally at both canvas edges.
      #
      # Three-step ribbon construction:
      #   1. Solid color rectangle with alpha channel (the ribbon body).
      #   2. CopyOpacity from a white-background/black-text mask to punch
      #      transparent holes in the shape of the letters.
      #   3. Re-annotate the label at 72% opacity to fill the holes with color.
      #
      # @param label     [String]  Banner text (auto-uppercased).
      # @param out_path  [String]  Destination PNG for the positioned ribbon canvas.
      # @param corner    [Symbol]  One of :bottom_right, :bottom_left, :top_right, :top_left.
      # @param style     [Symbol]  :dark or :light.
      # @param size      [Symbol]  :normal (14% of icon) or :large (17% of icon).
      # @param icon_size [Integer] Icon canvas size in pixels (usually 1024).
      def self.generate_corner_banner(label, out_path, corner: :bottom_right,
                                      style: :dark, size: :normal, icon_size: 1024)
        cfg      = CORNER_CFG[corner]
        angle    = cfg.angle
        bg_color = style == :dark ? DARK_BG : LIGHT_BG
        text_fill = style == :dark ? "rgba(255,255,255,0.72)" : "rgba(20,20,20,0.72)"

        # Ribbon dimensions
        ribbon_h_frac = size == :large ? 0.17 : 0.14
        ribbon_len    = (icon_size * 1.65).to_i
        ribbon_h      = (icon_size * ribbon_h_frac).to_i
        pointsize     = (ribbon_h * 0.91).to_i
        text_nudge_up = (ribbon_h * 0.05).to_i

        ribbon_path    = tmp_file("ribbon",    ".png")
        text_mask_path = tmp_file("text_mask", ".png")
        rotated_path   = tmp_file("rotated",   ".png")

        # Step 1: solid ribbon with alpha channel
        system(
          "magick",
          "-size", "#{ribbon_len}x#{ribbon_h}", "xc:#{bg_color}", "-alpha", "set",
          ribbon_path
        )

        # Step 2: CopyOpacity — punch transparent holes in the shape of the text.
        # White bg + black text mask: white → opaque ribbon, black → transparent hole.
        system(
          "magick",
          "-size", "#{ribbon_len}x#{ribbon_h}", "xc:white",
          "-fill", "black",
          "-font", FIGTREE_FONT,
          "-pointsize", pointsize.to_s,
          "-gravity", "Center",
          "-annotate", "0x0+0-#{text_nudge_up}", label.upcase,
          text_mask_path
        )
        system(
          "magick", ribbon_path, text_mask_path,
          "-compose", "CopyOpacity", "-composite",
          ribbon_path
        )

        # Step 3: re-render text at 72% opacity back into the holes.
        # The subtle knock-out effect lets a sliver of background bleed through.
        system(
          "magick", ribbon_path,
          "-fill", text_fill,
          "-font", FIGTREE_FONT,
          "-pointsize", pointsize.to_s,
          "-gravity", "Center",
          "-annotate", "0x0+0-#{text_nudge_up}", label.upcase,
          ribbon_path
        )

        # Rotate the ribbon (ImageMagick expands canvas with transparency)
        system(
          "magick", ribbon_path,
          "-background", "none",
          "-rotate", angle.to_s,
          rotated_path
        )

        # Drop shadow behind ribbon body (60% opacity, 10px blur, shifted 5px down)
        system(
          "magick",
          "(", rotated_path, "-alpha", "set", "-background", "none",
               "-shadow", "60x10+0+5",
          ")",
          rotated_path,
          "-background", "none", "-layers", "merge", "+repage",
          rotated_path
        )

        # Determine rotated image dimensions, then composite onto icon-sized canvas.
        # Position the ribbon so its center aligns with the corner's (cx, cy) fraction.
        rot_w, rot_h = IO.popen(
          ["magick", "identify", "-format", "%wx%h", rotated_path], &:read
        ).split("x").map(&:to_i)

        cx    = (icon_size * cfg.cx).to_i
        cy    = (icon_size * cfg.cy).to_i
        off_x = cx - rot_w / 2
        off_y = cy - rot_h / 2

        system(
          "magick",
          "-size", "#{icon_size}x#{icon_size}", "xc:none",
          rotated_path, "-geometry", "+#{off_x}+#{off_y}",
          "-composite",
          out_path
        )

        FileUtils.rm_f([ribbon_path, text_mask_path, rotated_path])
        out_path
      end

      # Composites a pre-positioned ribbon canvas over the icon in-place.
      # The banner PNG is icon-sized and fully transparent everywhere except
      # the ribbon, so a simple Over composite at (0,0) is sufficient.
      #
      # @param icon_path   [String]  Path to the icon PNG (modified in-place).
      # @param banner_path [String]  Path to the positioned ribbon canvas PNG.
      def self.composite_corner_banner(icon_path, banner_path)
        system(
          "magick", icon_path, banner_path,
          "-composite",
          icon_path
        )
      end

      # ────────────────────────────────────────────────────────────────────────
      # Private utilities
      # ────────────────────────────────────────────────────────────────────────

      # Returns a unique temp file path (not yet created).
      def self.tmp_file(prefix, suffix)
        File.join(Dir.tmpdir, "badger_#{prefix}_#{SecureRandom.hex(8)}#{suffix}")
      end
      private_class_method :tmp_file

      # Raises a UI error if the given font file does not exist.
      def self.validate_font!(font_path, name)
        return if File.exist?(font_path)
        UI.user_error!(
          "Font '#{name}' not found at #{font_path}.\n" \
          "Copy it into the gem's assets/fonts/ directory. " \
          "Both JetBrains Mono NL Bold (.ttf) and Figtree Black (.otf) are " \
          "distributed under the SIL Open Font License."
        )
      end
      private_class_method :validate_font!
    end
  end
end
