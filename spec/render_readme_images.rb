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

# ── Example 1: Dev / alpha build ─────────────────────────────────────────────
# All three actions: stamp_label_badge (north) + stamp_version_badge (center)
# + stamp_corner_banner. The most information-dense layout.
puts "1) Dev / alpha build — ticket + version + ALPHA corner"
icon = File.join(OUT_DIR, "example_1_alpha.png")
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

# ── Example 2: Beta build ─────────────────────────────────────────────────────
# stamp_version_badge (center) + stamp_corner_banner — no ticket badge.
puts "2) Beta build — version + BETA corner"
icon = File.join(OUT_DIR, "example_2_beta.png")
blue_icon(icon)
BadgerHelper.stamp_text(
  icon_path:     icon,
  center_top:    "2.1.0",
  center_bottom: "1042"
)
BadgerHelper.stamp_corner_banner(icon_path: icon, label: "BETA", corner: :bottom_right, style: :light, size: :normal)
puts "   → #{icon}"

# ── Example 3: Corner banner only ────────────────────────────────────────────
# stamp_corner_banner only — no text badges at all.
puts "3) Corner only — BETA banner"
icon = File.join(OUT_DIR, "example_3_corner_only.png")
blue_icon(icon)
BadgerHelper.stamp_corner_banner(icon_path: icon, label: "BETA", corner: :bottom_right, style: :light, size: :normal)
puts "   → #{icon}"

# ── Anatomy ───────────────────────────────────────────────────────────────────
# Every available slot active simultaneously:
#   North slot:  north_left (grey) + north_right (orange)
#   Center slot: center_top (grey) + center_bottom (orange)
#   Corner banner
# Shows the complete two-slot layout in one image.
puts "4) Anatomy — all slots active: north (left+right), center (top+bottom), corner"
icon = File.join(OUT_DIR, "example_anatomy.png")
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

# ── Open all results ──────────────────────────────────────────────────────────

results = Dir.glob(File.join(OUT_DIR, "example_*.png")).sort
system("open", *results)

puts "\nDone — #{results.count} images written to gh-docs/ and opened in Preview.\n"
