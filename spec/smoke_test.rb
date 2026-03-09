# badger — fastlane-plugin-badger
# smoke_test.rb
#
# Created by Richard P. Ulivella on 09 Mar 2026.
# Copyright © 2026 Richard P. Ulivella. All rights reserved.
#
# Loads the gem directly from the local repo and runs all three actions
# against a generated test icon. Results open in Preview automatically.
#
# Run from the gem root:
#   ruby spec/smoke_test.rb

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

OUT_DIR = File.join(Dir.tmpdir, "badger_smoke")
FileUtils.mkdir_p(OUT_DIR)

# ── helpers ──────────────────────────────────────────────────────────────────

def blue_icon(path, size: 1024)
  system("magick", "-size", "#{size}x#{size}", "xc:#4a70d4", path)
end

def copy(src, dst)
  FileUtils.cp(src, dst)
  dst
end

puts "\nbadger smoke test — output: #{OUT_DIR}\n\n"

# ── A: stamp_version_badge ───────────────────────────────────────────────────

puts "A) stamp_version_badge"
icon_a = File.join(OUT_DIR, "A_version.png")
blue_icon(icon_a)
BadgerHelper.stamp_text(icon_path: icon_a, version: "1.5.2", build: "1234")
puts "   → #{icon_a}"

# ── B: stamp_label_badge ─────────────────────────────────────────────────────

puts "B) stamp_label_badge"
icon_b = File.join(OUT_DIR, "B_label.png")
blue_icon(icon_b)
BadgerHelper.stamp_text(icon_path: icon_b, version: nil, build: nil, ticket: "TKT-1234")
puts "   → #{icon_b}"

# ── C: stamp_version + label combined ────────────────────────────────────────

puts "C) stamp_version + label combined"
icon_c = File.join(OUT_DIR, "C_combined.png")
blue_icon(icon_c)
BadgerHelper.stamp_text(icon_path: icon_c, version: "1.5.2", build: "1234", ticket: "TKT-1234")
puts "   → #{icon_c}"

# ── D: corner banners — all four corners, normal size ────────────────────────

puts "D) stamp_corner_banner — all four corners (BETA, normal)"
%i[bottom_right bottom_left top_right top_left].each do |corner|
  name = "D_beta_#{corner}.png"
  icon = File.join(OUT_DIR, name)
  blue_icon(icon)
  BadgerHelper.stamp_corner_banner(icon_path: icon, label: "BETA", corner: corner, style: :light, size: :normal)
  puts "   → #{icon}"
end

# ── E: corner banners — all four corners, large size ("BIG") ─────────────────

puts "E) stamp_corner_banner — all four corners (BIG, large)"
%i[bottom_right bottom_left top_right top_left].each do |corner|
  name = "E_big_#{corner}.png"
  icon = File.join(OUT_DIR, name)
  blue_icon(icon)
  BadgerHelper.stamp_corner_banner(icon_path: icon, label: "BIG", corner: corner, style: :light, size: :large)
  puts "   → #{icon}"
end

# ── open all results ──────────────────────────────────────────────────────────

results = Dir.glob(File.join(OUT_DIR, "*.png")).sort
system("open", *results)

puts "\nDone — #{results.count} icons opened in Preview.\n"
