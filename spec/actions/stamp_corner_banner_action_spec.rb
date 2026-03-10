# badger — fastlane-plugin-badger
# stamp_corner_banner_action_spec.rb
#
# Created by Richard P. Ulivella on 10 Mar 2026.
# Copyright © 2026 Richard P. Ulivella. All rights reserved.

require "spec_helper"

RSpec.describe Fastlane::Actions::StampCornerBannerAction do
  subject(:action) { described_class }

  def params(overrides = {})
    {
      label:     "ALPHA",
      corner:    "bottom_right",
      style:     "dark",
      size:      "normal",
      icon_glob: "**/AppIcon.appiconset/*.png"
    }.merge(overrides)
  end

  before { allow(Dir).to receive(:glob).and_return([]) }

  describe ".run" do
    # ── Input validation ────────────────────────────────────────────────────

    it "raises when label is nil" do
      expect { action.run(params(label: nil)) }.to raise_error(/label is required/)
    end

    it "raises when label is an empty string" do
      expect { action.run(params(label: "")) }.to raise_error(/label is required/)
    end

    it "raises when label is blank whitespace" do
      expect { action.run(params(label: "   ")) }.to raise_error(/label is required/)
    end

    it "raises for an invalid corner value" do
      expect { action.run(params(corner: "center")) }.to raise_error(/corner must be one of/)
    end

    it "raises for an invalid style value" do
      expect { action.run(params(style: "purple")) }.to raise_error(/style must be one of/)
    end

    it "raises for an invalid size value" do
      expect { action.run(params(size: "huge")) }.to raise_error(/size must be one of/)
    end

    # ── No-icons early exit ─────────────────────────────────────────────────

    it "logs important and returns when no icons match the glob" do
      expect(Fastlane::UI).to receive(:important).with(/no icons matched/)
      action.run(params)
    end

    # ── Happy path ──────────────────────────────────────────────────────────

    context "when icons are matched" do
      before do
        allow(Dir).to receive(:glob).and_return(["/tmp/icon1.png", "/tmp/icon2.png"])
        allow(Fastlane::Helper::BadgerHelper).to receive(:stamp_corner_banner)
        allow(Fastlane::UI).to receive(:message)
      end

      it "calls stamp_corner_banner for every matched icon" do
        action.run(params(label: "BETA", corner: "top_left", style: "light", size: "large"))
        expect(Fastlane::Helper::BadgerHelper).to have_received(:stamp_corner_banner)
          .with(icon_path: "/tmp/icon1.png", label: "BETA",
                corner: :top_left, style: :light, size: :large)
        expect(Fastlane::Helper::BadgerHelper).to have_received(:stamp_corner_banner)
          .with(icon_path: "/tmp/icon2.png", label: "BETA",
                corner: :top_left, style: :light, size: :large)
      end

      it "passes corner as symbol" do
        allow(Dir).to receive(:glob).and_return(["/tmp/icon.png"])
        action.run(params(corner: "bottom_left"))
        expect(Fastlane::Helper::BadgerHelper).to have_received(:stamp_corner_banner)
          .with(hash_including(corner: :bottom_left))
      end

      it "passes style as symbol" do
        allow(Dir).to receive(:glob).and_return(["/tmp/icon.png"])
        action.run(params(style: "light"))
        expect(Fastlane::Helper::BadgerHelper).to have_received(:stamp_corner_banner)
          .with(hash_including(style: :light))
      end

      it "passes size as symbol" do
        allow(Dir).to receive(:glob).and_return(["/tmp/icon.png"])
        action.run(params(size: "large"))
        expect(Fastlane::Helper::BadgerHelper).to have_received(:stamp_corner_banner)
          .with(hash_including(size: :large))
      end

      it "accepts all four valid corners" do
        %w[bottom_right bottom_left top_right top_left].each do |corner|
          expect { action.run(params(corner: corner)) }.not_to raise_error
        end
      end

      it "accepts both valid styles" do
        %w[dark light].each do |style|
          expect { action.run(params(style: style)) }.not_to raise_error
        end
      end

      it "accepts both valid sizes" do
        %w[normal large].each do |size|
          expect { action.run(params(size: size)) }.not_to raise_error
        end
      end
    end
  end

  describe ".is_supported?" do
    it "supports :ios" do
      expect(action.is_supported?(:ios)).to be true
    end

    it "supports :mac" do
      expect(action.is_supported?(:mac)).to be true
    end

    it "does not support :android" do
      expect(action.is_supported?(:android)).to be false
    end
  end

  describe ".description" do
    it "returns a non-empty string" do
      expect(action.description).to be_a(String)
      expect(action.description).not_to be_empty
    end
  end
end
