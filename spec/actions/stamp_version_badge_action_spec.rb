# badger — fastlane-plugin-badger
# stamp_version_badge_action_spec.rb
#
# Created by Richard P. Ulivella on 10 Mar 2026.
# Copyright © 2026 Richard P. Ulivella. All rights reserved.

require "spec_helper"

RSpec.describe Fastlane::Actions::StampVersionBadgeAction do
  subject(:action) { described_class }

  def params(overrides = {})
    {
      version:   "1.5.2",
      build:     "6349",
      xcodeproj: nil,
      icon_glob: "**/AppIcon.appiconset/*.png"
    }.merge(overrides)
  end

  before { allow(Dir).to receive(:glob).and_return([]) }

  describe ".run" do
    # ── Input validation ────────────────────────────────────────────────────

    it "raises when version is nil and no xcodeproj" do
      expect { action.run(params(version: nil)) }.to raise_error(/version is required/)
    end

    it "raises when version is an empty string" do
      expect { action.run(params(version: "")) }.to raise_error(/version is required/)
    end

    it "raises when version is blank whitespace" do
      expect { action.run(params(version: "  ")) }.to raise_error(/version is required/)
    end

    it "raises when build is nil and no xcodeproj" do
      expect { action.run(params(build: nil)) }.to raise_error(/build is required/)
    end

    it "raises when build is an empty string" do
      expect { action.run(params(build: "")) }.to raise_error(/build is required/)
    end

    # ── No-icons early exit ─────────────────────────────────────────────────

    it "logs important and returns when no icons match the glob" do
      expect(Fastlane::UI).to receive(:important).with(/no icons matched/)
      action.run(params)
    end

    # ── Happy path ──────────────────────────────────────────────────────────

    context "when icons are matched" do
      before do
        allow(Dir).to receive(:glob).and_return(["/tmp/icon.png"])
        allow(Fastlane::Helper::BadgerHelper).to receive(:stamp_text)
        allow(Fastlane::UI).to receive(:message)
      end

      it "calls stamp_text with center_top (version) and center_bottom (build)" do
        action.run(params(version: "2.0.0", build: "100"))
        expect(Fastlane::Helper::BadgerHelper).to have_received(:stamp_text)
          .with(icon_path: "/tmp/icon.png", center_top: "2.0.0", center_bottom: "100")
      end

      it "converts build to string" do
        action.run(params(build: 999))
        expect(Fastlane::Helper::BadgerHelper).to have_received(:stamp_text)
          .with(hash_including(center_bottom: "999"))
      end

      it "calls stamp_text for each matched icon" do
        allow(Dir).to receive(:glob).and_return(["/tmp/a.png", "/tmp/b.png"])
        action.run(params)
        expect(Fastlane::Helper::BadgerHelper).to have_received(:stamp_text).twice
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
