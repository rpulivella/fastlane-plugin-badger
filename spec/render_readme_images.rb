# badger — fastlane-plugin-badger
# render_readme_images.rb
#
# Created by Richard P. Ulivella on 10 Mar 2026.
# Copyright © 2026 Richard P. Ulivella. All rights reserved.
#
# Generates the example images used in README.md and stores them in gh-docs/.
# Run this whenever the README examples need to be refreshed.
# Uses the same infrastructure as smoke_test.rb (known working).
#
# Run from the gem root:
#   ruby spec/render_readme_images.rb

require "mini_magick"
require "tmpdir"
require "fileutils"

GEM_ROOT = File.expand_path("..", __dir__)
$LOAD_PATH.unshift(File.join(GEM_ROOT, "lib"))

# Minimal Fastlane::UI stub so the helper runs without the full Fastlane stack
module Fastlane
  module UI
    def self.message(msg) = puts(msg)
    def self.important(msg) = puts("  [!] #{msg}")
    def self.user_error!(msg) = raise(msg)
  end
end

require "fastlane/plugin/badger/helper/badger_helper"

include Fastlane::Helper

OUT_DIR = File.join(GEM_ROOT, "gh-docs")
FileUtils.mkdir_p(OUT_DIR)

def blue_icon(path, size: 1024)
  system("magick", "-size", "#{size}x#{size}", "xc:#4a70d4", path)
end

puts "\nRendering README images → #{OUT_DIR}\n\n"

# ── Examples: stamp_label_badge + stamp_version_badge + stamp_corner_banner ──

puts "example_1: north_left + north_right + center_top + center_bottom + corner"
icon = File.join(OUT_DIR, "example_1_all_actions.png")
blue_icon(icon)
BadgerHelper.stamp_text(
  icon_path:     icon,
  north_left:    "APP",
  north_right:   "1042",
  center_top:    "2.1.0",
  center_bottom: "1042"
)
BadgerHelper.stamp_corner_banner(icon_path: icon, label: "ALPHA", corner: :bottom_right, style: :light, size: :normal)
puts "   → #{icon}"

puts "example_2: center_top + center_bottom + corner"
icon = File.join(OUT_DIR, "example_2_version_corner.png")
blue_icon(icon)
BadgerHelper.stamp_text(
  icon_path:     icon,
  center_top:    "2.1.0",
  center_bottom: "1042"
)
BadgerHelper.stamp_corner_banner(icon_path: icon, label: "BETA", corner: :bottom_right, style: :light, size: :normal)
puts "   → #{icon}"

puts "example_3: corner only"
icon = File.join(OUT_DIR, "example_3_corner_only.png")
blue_icon(icon)
BadgerHelper.stamp_corner_banner(icon_path: icon, label: "BETA", corner: :bottom_right, style: :light, size: :normal)
puts "   → #{icon}"

# ── Anatomy: badge slots ──────────────────────────────────────────────────────

puts "anatomy_slots: north_left + north_right + center_top + center_bottom (no corner)"
icon = File.join(OUT_DIR, "anatomy_slots.png")
blue_icon(icon)
BadgerHelper.stamp_text(
  icon_path:     icon,
  north_left:    "APP",
  north_right:   "1042",
  center_top:    "2.1.0",
  center_bottom: "1042"
)
puts "   → #{icon}"

# ── Anatomy: corner positions ─────────────────────────────────────────────────

puts "anatomy_corner_*: all four corner positions"
%i[bottom_right bottom_left top_right top_left].each do |corner|
  icon = File.join(OUT_DIR, "anatomy_corner_#{corner}.png")
  blue_icon(icon)
  BadgerHelper.stamp_corner_banner(icon_path: icon, label: "ALPHA", corner: corner, style: :light, size: :normal)
  puts "   → #{icon}"
end

# ── Anatomy: size — normal vs large ──────────────────────────────────────────

puts "anatomy_size_normal: size: :normal"
icon = File.join(OUT_DIR, "anatomy_size_normal.png")
blue_icon(icon)
BadgerHelper.stamp_corner_banner(icon_path: icon, label: "ALPHA", corner: :bottom_right, style: :light, size: :normal)
puts "   → #{icon}"

puts "anatomy_size_large: size: :large"
icon = File.join(OUT_DIR, "anatomy_size_large.png")
blue_icon(icon)
BadgerHelper.stamp_corner_banner(icon_path: icon, label: "ALPHA", corner: :bottom_right, style: :light, size: :large)
puts "   → #{icon}"

# ── Anatomy: style — light vs dark ───────────────────────────────────────────

puts "anatomy_style_light: style: :light"
icon = File.join(OUT_DIR, "anatomy_style_light.png")
blue_icon(icon)
BadgerHelper.stamp_corner_banner(icon_path: icon, label: "ALPHA", corner: :bottom_right, style: :light, size: :normal)
puts "   → #{icon}"

puts "anatomy_style_dark: style: :dark"
icon = File.join(OUT_DIR, "anatomy_style_dark.png")
blue_icon(icon)
BadgerHelper.stamp_corner_banner(icon_path: icon, label: "ALPHA", corner: :bottom_right, style: :dark, size: :normal)
puts "   → #{icon}"

# ── Open all results ──────────────────────────────────────────────────────────

results = Dir.glob(File.join(OUT_DIR, "*.png")).sort
system("open", *results)

puts "\nDone — #{results.count} images written to gh-docs/ and opened in Preview.\n"
