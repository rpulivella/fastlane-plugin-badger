# badger — fastlane-plugin-badger
# stamp_label_badge_action_spec.rb
#
# Created by Richard P. Ulivella on 10 Mar 2026.
# Copyright © 2026 Richard P. Ulivella. All rights reserved.

require "spec_helper"

RSpec.describe Fastlane::Actions::StampLabelBadgeAction do
  subject(:action) { described_class }

  before { allow(Dir).to receive(:glob).and_return([]) }

  describe ".run" do
    # ── Input validation ────────────────────────────────────────────────────

    it "raises when both north_left and north_right are nil" do
      expect {
        action.run({ north_left: nil, north_right: nil, icon_glob: "**/*.png" })
      }.to raise_error(/At least one/)
    end

    it "raises when both are empty strings" do
      expect {
        action.run({ north_left: "", north_right: "", icon_glob: "**/*.png" })
      }.to raise_error(/At least one/)
    end

    it "raises when both are blank whitespace" do
      expect {
        action.run({ north_left: "   ", north_right: "  ", icon_glob: "**/*.png" })
      }.to raise_error(/At least one/)
    end

    # ── No-icons early exit ─────────────────────────────────────────────────

    it "logs important and returns when no icons match the glob" do
      expect(Fastlane::UI).to receive(:important).with(/no icons matched/)
      action.run({ north_left: "APP", north_right: nil, icon_glob: "**/*.png" })
    end

    # ── Happy path ──────────────────────────────────────────────────────────

    context "when icons are matched" do
      before do
        allow(Dir).to receive(:glob).and_return(["/tmp/icon.png"])
        allow(Fastlane::Helper::BadgerHelper).to receive(:stamp_text)
        allow(Fastlane::UI).to receive(:message)
      end

      it "calls stamp_text with north_left only" do
        action.run({ north_left: "APP", north_right: nil, icon_glob: "**/*.png" })
        expect(Fastlane::Helper::BadgerHelper).to have_received(:stamp_text)
          .with(icon_path: "/tmp/icon.png", north_left: "APP", north_right: nil)
      end

      it "calls stamp_text with north_right only" do
        action.run({ north_left: nil, north_right: "1042", icon_glob: "**/*.png" })
        expect(Fastlane::Helper::BadgerHelper).to have_received(:stamp_text)
          .with(icon_path: "/tmp/icon.png", north_left: nil, north_right: "1042")
      end

      it "calls stamp_text with both slots" do
        action.run({ north_left: "APP", north_right: "1042", icon_glob: "**/*.png" })
        expect(Fastlane::Helper::BadgerHelper).to have_received(:stamp_text)
          .with(icon_path: "/tmp/icon.png", north_left: "APP", north_right: "1042")
      end

      it "calls stamp_text for each matched icon" do
        allow(Dir).to receive(:glob).and_return(["/tmp/a.png", "/tmp/b.png"])
        action.run({ north_left: "APP", north_right: nil, icon_glob: "**/*.png" })
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
