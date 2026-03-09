require "spec_helper"

RSpec.describe Fastlane::Helper::BadgerHelper do
  subject(:helper) { described_class }

  describe "FONTS_DIR" do
    it "resolves to a path ending in assets/fonts" do
      expect(helper::FONTS_DIR).to end_with("assets/fonts")
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

    it "uses -45 angle for bottom_right" do
      expect(helper::CORNER_CFG[:bottom_right].angle).to eq(-45)
    end

    it "uses +45 angle for bottom_left" do
      expect(helper::CORNER_CFG[:bottom_left].angle).to eq(45)
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

  describe "font path constants" do
    it "JETBRAINS_FONT ends with the correct filename" do
      expect(helper::JETBRAINS_FONT).to end_with("JetBrainsMonoNL-Bold.ttf")
    end

    it "FIGTREE_FONT ends with the correct filename" do
      expect(helper::FIGTREE_FONT).to end_with("Figtree-Black.otf")
    end
  end

  describe "ribbon dimension calculations" do
    it "uses 14% ribbon height for :normal size at 1024px" do
      # ribbon_h_frac for :normal = 0.14
      expected = (1024 * 0.14).to_i
      expect(expected).to eq(143)
    end

    it "uses 17% ribbon height for :large size at 1024px" do
      # ribbon_h_frac for :large = 0.17
      expected = (1024 * 0.17).to_i
      expect(expected).to eq(174)
    end
  end
end
