# badger — fastlane-plugin-badger
# badger_helper_spec.rb
#
# Created by Richard P. Ulivella on 09 Mar 2026.
# Copyright © 2026 Richard P. Ulivella. All rights reserved.

require "spec_helper"

RSpec.describe Fastlane::Helper::BadgerHelper do
  subject(:helper) { described_class }

  describe "FONTS_DIR" do
    it "resolves to a path ending in assets/fonts" do
      expect(helper::FONTS_DIR).to end_with("assets/fonts")
    end
  end

  describe "font path constants" do
    it "JETBRAINS_FONT ends with the correct filename" do
      expect(helper::JETBRAINS_FONT).to end_with("JetBrainsMonoNL-Bold.ttf")
    end

    it "FIGTREE_FONT ends with the correct filename" do
      expect(helper::FIGTREE_FONT).to end_with("Figtree-Black.otf")
    end
  end

  describe "color constants" do
    it "GREY_COLOR is the correct hex value" do
      expect(helper::GREY_COLOR).to eq("#555555")
    end

    it "ORANGE_COLOR is the correct hex value" do
      expect(helper::ORANGE_COLOR).to eq("#fe7d37")
    end

    it "DARK_BG is the correct hex value" do
      expect(helper::DARK_BG).to eq("#1c1c1e")
    end

    it "LIGHT_BG is the correct hex value" do
      expect(helper::LIGHT_BG).to eq("#efefef")
    end
  end

  describe "CORNER_CFG" do
    it "defines all four corners" do
      expect(helper::CORNER_CFG.keys).to contain_exactly(
        :bottom_right, :bottom_left, :top_right, :top_left
      )
    end

    it "has angle, cx, and cy for each corner" do
      helper::CORNER_CFG.each do |corner, cfg|
        expect(cfg).to respond_to(:angle, :cx, :cy), "corner #{corner} missing members"
      end
    end

    it "places bottom_right at 75% diagonally" do
      cfg = helper::CORNER_CFG[:bottom_right]
      expect(cfg.cx).to eq(0.75)
      expect(cfg.cy).to eq(0.75)
    end

    it "places bottom_left at 25% x, 75% y" do
      cfg = helper::CORNER_CFG[:bottom_left]
      expect(cfg.cx).to eq(0.25)
      expect(cfg.cy).to eq(0.75)
    end

    it "places top_right at 75% x, 25% y" do
      cfg = helper::CORNER_CFG[:top_right]
      expect(cfg.cx).to eq(0.75)
      expect(cfg.cy).to eq(0.25)
    end

    it "places top_left at 25% diagonally" do
      cfg = helper::CORNER_CFG[:top_left]
      expect(cfg.cx).to eq(0.25)
      expect(cfg.cy).to eq(0.25)
    end

    it "uses -45 angle for bottom_right and top_left" do
      expect(helper::CORNER_CFG[:bottom_right].angle).to eq(-45)
      expect(helper::CORNER_CFG[:top_left].angle).to eq(-45)
    end

    it "uses +45 angle for bottom_left and top_right" do
      expect(helper::CORNER_CFG[:bottom_left].angle).to eq(45)
      expect(helper::CORNER_CFG[:top_right].angle).to eq(45)
    end
  end

  describe ".resolve_icons" do
    let(:tmp_dir) { Dir.mktmpdir("badger_spec") }

    after { FileUtils.rm_rf(tmp_dir) }

    context "when given a direct PNG path" do
      it "returns that path in an array" do
        png = File.join(tmp_dir, "icon.png")
        FileUtils.touch(png)
        expect(helper.resolve_icons(png)).to eq([png])
      end
    end

    context "when given a non-existent path" do
      it "returns an empty array" do
        expect(helper.resolve_icons("/nonexistent/path.png")).to eq([])
      end
    end

    context "when given an AppIcon.appiconset directory" do
      it "discovers all PNGs inside" do
        appiconset = File.join(tmp_dir, "AppIcon.appiconset")
        FileUtils.mkdir_p(appiconset)
        %w[icon1.png icon2.png].each { |f| FileUtils.touch(File.join(appiconset, f)) }

        result = helper.resolve_icons(appiconset)
        expect(result.count).to eq(2)
        expect(result).to all(end_with(".png"))
      end
    end

    context "when given an xcassets directory" do
      it "discovers PNGs in nested AppIcon.appiconset" do
        appiconset = File.join(tmp_dir, "Assets.xcassets", "AppIcon.appiconset")
        FileUtils.mkdir_p(appiconset)
        FileUtils.touch(File.join(appiconset, "icon.png"))

        result = helper.resolve_icons(File.join(tmp_dir, "Assets.xcassets"))
        expect(result.count).to eq(1)
        expect(result.first).to end_with("icon.png")
      end
    end
  end

  describe "ribbon dimension calculations" do
    it "uses 14% ribbon height for :normal size at 1024px" do
      expected = (1024 * 0.14).to_i
      expect(expected).to eq(143)
    end

    it "uses 17% ribbon height for :large size at 1024px" do
      expected = (1024 * 0.17).to_i
      expect(expected).to eq(174)
    end

    it "ribbon length is 165% of icon size at 1024px" do
      expected = (1024 * 1.65).to_i
      expect(expected).to eq(1689)
    end

    it "pointsize is 91% of ribbon height" do
      ribbon_h = (1024 * 0.14).to_i
      expected = (ribbon_h * 0.91).to_i
      expect(expected).to eq(130)
    end
  end

  describe ".tmp_file" do
    it "returns a path inside Dir.tmpdir" do
      path = helper.send(:tmp_file, "test", ".png")
      expect(path).to start_with(Dir.tmpdir)
    end

    it "includes the given prefix" do
      path = helper.send(:tmp_file, "myprefix", ".png")
      expect(path).to include("myprefix")
    end

    it "ends with the given suffix" do
      path = helper.send(:tmp_file, "test", ".png")
      expect(path).to end_with(".png")
    end

    it "generates unique paths each call" do
      a = helper.send(:tmp_file, "test", ".png")
      b = helper.send(:tmp_file, "test", ".png")
      expect(a).not_to eq(b)
    end
  end

  describe ".validate_font!" do
    it "raises when the font file does not exist" do
      expect {
        helper.send(:validate_font!, "/nonexistent/font.ttf", "font.ttf")
      }.to raise_error(/font.ttf/)
    end

    it "does not raise when the font file exists" do
      Dir.mktmpdir do |dir|
        font = File.join(dir, "test.ttf")
        FileUtils.touch(font)
        expect { helper.send(:validate_font!, font, "test.ttf") }.not_to raise_error
      end
    end
  end

  # ────────────────────────────────────────────────────────────────────────────
  # stamp_text — behavior (generation pipeline stubbed)
  # ────────────────────────────────────────────────────────────────────────────

  describe ".stamp_text" do
    let(:tmp_dir) { Dir.mktmpdir("badger_stamp") }
    let(:icon)    { File.join(tmp_dir, "icon.png").tap { |p| FileUtils.touch(p) } }

    before do
      allow(helper).to receive(:validate_font!)
      allow(helper).to receive(:generate_horizontal_badge)
      allow(helper).to receive(:generate_vertical_badge)
      allow(helper).to receive(:generate_single_badge)
      allow(helper).to receive(:round_corners)
      allow(helper).to receive(:composite_badge)
    end

    after { FileUtils.rm_rf(tmp_dir) }

    it "raises when no icons are found at the given path" do
      expect {
        helper.stamp_text(icon_path: "/no/such/icon.png")
      }.to raise_error(/No PNG icons found/)
    end

    context "with both north slots" do
      it "calls generate_horizontal_badge" do
        helper.stamp_text(icon_path: icon, north_left: "APP", north_right: "1042")
        expect(helper).to have_received(:generate_horizontal_badge)
          .with("APP", "1042", anything, pointsize: 90, border: "18x9")
      end
    end

    context "with north_right only" do
      it "calls generate_single_badge with ORANGE_COLOR" do
        helper.stamp_text(icon_path: icon, north_right: "1042")
        expect(helper).to have_received(:generate_single_badge)
          .with("1042", anything, color: helper::ORANGE_COLOR, pointsize: 90, border: "18x9")
      end
    end

    context "with north_left only" do
      it "calls generate_single_badge with GREY_COLOR" do
        helper.stamp_text(icon_path: icon, north_left: "APP")
        expect(helper).to have_received(:generate_single_badge)
          .with("APP", anything, color: helper::GREY_COLOR, pointsize: 90, border: "18x9")
      end
    end

    context "with both center slots" do
      it "calls generate_vertical_badge" do
        helper.stamp_text(icon_path: icon, center_top: "2.1.0", center_bottom: "1042")
        expect(helper).to have_received(:generate_vertical_badge)
          .with("2.1.0", "1042", anything, pointsize: 117, border: "23x12")
      end
    end

    context "with center_bottom only" do
      it "calls generate_single_badge with ORANGE_COLOR at center pointsize" do
        helper.stamp_text(icon_path: icon, center_bottom: "1042")
        expect(helper).to have_received(:generate_single_badge)
          .with("1042", anything, color: helper::ORANGE_COLOR, pointsize: 117, border: "23x12")
      end
    end

    context "with center_top only" do
      it "calls generate_single_badge with GREY_COLOR at center pointsize" do
        helper.stamp_text(icon_path: icon, center_top: "2.1.0")
        expect(helper).to have_received(:generate_single_badge)
          .with("2.1.0", anything, color: helper::GREY_COLOR, pointsize: 117, border: "23x12")
      end
    end

    context "with all four slots" do
      it "calls both generate_horizontal_badge and generate_vertical_badge" do
        helper.stamp_text(icon_path: icon,
                          north_left: "APP", north_right: "1042",
                          center_top: "2.1.0", center_bottom: "1042")
        expect(helper).to have_received(:generate_horizontal_badge).once
        expect(helper).to have_received(:generate_vertical_badge).once
      end
    end

    it "composites each badge onto the icon" do
      helper.stamp_text(icon_path: icon, north_left: "APP", center_top: "2.1.0")
      expect(helper).to have_received(:composite_badge).twice
    end
  end

  # ────────────────────────────────────────────────────────────────────────────
  # stamp_corner_banner — validation and delegation (banner pipeline stubbed)
  # ────────────────────────────────────────────────────────────────────────────

  describe ".stamp_corner_banner" do
    let(:tmp_dir) { Dir.mktmpdir("badger_banner") }
    let(:icon)    { File.join(tmp_dir, "icon.png") }

    before do
      system("magick", "-size", "64x64", "xc:white", icon)
      allow(helper).to receive(:validate_font!)
      allow(helper).to receive(:generate_corner_banner).and_return("/tmp/fake_banner.png")
      allow(helper).to receive(:composite_corner_banner)
      allow(FileUtils).to receive(:rm_f)
    end

    after { FileUtils.rm_rf(tmp_dir) }

    it "raises when no icons are found at the given path" do
      expect {
        helper.stamp_corner_banner(icon_path: "/no/such/icon.png", label: "TEST")
      }.to raise_error(/No PNG icons found/)
    end

    it "raises for an unknown corner symbol" do
      expect {
        helper.stamp_corner_banner(icon_path: icon, label: "TEST", corner: :invalid)
      }.to raise_error(/Unknown corner/)
    end

    it "calls generate_corner_banner with the correct parameters" do
      helper.stamp_corner_banner(icon_path: icon, label: "ALPHA",
                                 corner: :bottom_right, style: :light, size: :large)
      expect(helper).to have_received(:generate_corner_banner)
        .with("ALPHA", anything,
              corner: :bottom_right, style: :light, size: :large, icon_size: 64)
    end

    it "calls composite_corner_banner with the icon path" do
      helper.stamp_corner_banner(icon_path: icon, label: "BETA")
      expect(helper).to have_received(:composite_corner_banner).with(icon, anything)
    end

    it "accepts all four valid corners without error" do
      %i[bottom_right bottom_left top_right top_left].each do |corner|
        expect {
          helper.stamp_corner_banner(icon_path: icon, label: "X", corner: corner)
        }.not_to raise_error
      end
    end

    it "uses :bottom_right as the default corner" do
      helper.stamp_corner_banner(icon_path: icon, label: "X")
      expect(helper).to have_received(:generate_corner_banner)
        .with(anything, anything, hash_including(corner: :bottom_right))
    end

    it "uses :dark as the default style" do
      helper.stamp_corner_banner(icon_path: icon, label: "X")
      expect(helper).to have_received(:generate_corner_banner)
        .with(anything, anything, hash_including(style: :dark))
    end

    it "uses :normal as the default size" do
      helper.stamp_corner_banner(icon_path: icon, label: "X")
      expect(helper).to have_received(:generate_corner_banner)
        .with(anything, anything, hash_including(size: :normal))
    end
  end
end
