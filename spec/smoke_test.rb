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

# ── A: center slot only (stamp_version_badge equivalent) ─────────────────────

puts "A) Center slot — version (grey top) + build (orange bottom)"
icon_a = File.join(OUT_DIR, "A_center_version_build.png")
blue_icon(icon_a)
BadgerHelper.stamp_text(icon_path: icon_a, center_top: "1.5.2", center_bottom: "6349")
puts "   → #{icon_a}"

# ── B: north slot only — two sub-slots (stamp_label_badge equivalent) ────────

puts "B) North slot — LIG (grey left) + 2969 (orange right)"
icon_b = File.join(OUT_DIR, "B_north_ticket.png")
blue_icon(icon_b)
BadgerHelper.stamp_text(icon_path: icon_b, north_left: "LIG", north_right: "2969")
puts "   → #{icon_b}"

# ── C: north + center combined (Slyyd Alpha layout) ──────────────────────────

puts "C) North + Center combined — Slyyd Alpha layout"
icon_c = File.join(OUT_DIR, "C_slyyd_alpha.png")
blue_icon(icon_c)
BadgerHelper.stamp_text(
  icon_path:     icon_c,
  north_left:    "LIG",
  north_right:   "2969",
  center_top:    "1.5.2",
  center_bottom: "6349"
)
puts "   → #{icon_c}"

# ── D: north + center + corner banner (full Slyyd Alpha) ─────────────────────

puts "D) Full Slyyd Alpha — North + Center + ALPHA banner"
icon_d = File.join(OUT_DIR, "D_slyyd_alpha_full.png")
blue_icon(icon_d)
BadgerHelper.stamp_text(
  icon_path:     icon_d,
  north_left:    "LIG",
  north_right:   "2969",
  center_top:    "1.5.2",
  center_bottom: "6349"
)
BadgerHelper.stamp_corner_banner(icon_path: icon_d, label: "ALPHA", corner: :bottom_right, style: :light, size: :normal)
puts "   → #{icon_d}"

# ── E: north single sub-slot only (north_right only) ─────────────────────────

puts "E) North slot — right only (single orange)"
icon_e = File.join(OUT_DIR, "E_north_right_only.png")
blue_icon(icon_e)
BadgerHelper.stamp_text(icon_path: icon_e, north_right: "PR-42")
puts "   → #{icon_e}"

# ── F: center single sub-slot only (center_bottom only) ──────────────────────

puts "F) Center slot — bottom only (single orange)"
icon_f = File.join(OUT_DIR, "F_center_bottom_only.png")
blue_icon(icon_f)
BadgerHelper.stamp_text(icon_path: icon_f, center_bottom: "6349")
puts "   → #{icon_f}"

# ── G: corner banners — all four corners, normal size ────────────────────────

puts "G) stamp_corner_banner — all four corners (BETA, normal)"
%i[bottom_right bottom_left top_right top_left].each do |corner|
  name = "G_beta_#{corner}.png"
  icon = File.join(OUT_DIR, name)
  blue_icon(icon)
  BadgerHelper.stamp_corner_banner(icon_path: icon, label: "BETA", corner: corner, style: :light, size: :normal)
  puts "   → #{icon}"
end

# ── H: corner banners — large size ("NDA") ───────────────────────────────────

puts "H) stamp_corner_banner — bottom_right (NDA, large)"
icon_h = File.join(OUT_DIR, "H_nda_large.png")
blue_icon(icon_h)
BadgerHelper.stamp_corner_banner(icon_path: icon_h, label: "NDA", corner: :bottom_right, style: :light, size: :large)
puts "   → #{icon_h}"

# ── open all results ──────────────────────────────────────────────────────────

results = Dir.glob(File.join(OUT_DIR, "*.png")).sort
system("open", *results)

puts "\nDone — #{results.count} icons opened in Preview.\n"
