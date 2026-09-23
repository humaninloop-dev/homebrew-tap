# Kinako — Homebrew Cask. **This file is the source of truth**; the release job renders it to
# humaninloop-dev/homebrew-tap:Casks/kinako.rb with `version` and `sha256` substituted.
#
# The 0.3.0 cask this replaces carried the same claim in its own header, the same dogfood
# posture, and most of the same text. What is kept from it is kept deliberately — the `sbx`
# dependency, the quarantine-stripping postflight, the livecheck skip and every `zap` entry
# including the bare `kinako` one, whose in-file comment recorded that every dogfood install
# before MVP-H1 leaked its whole store without it.
#
# Dogfood posture (founder ruling 2026-07-24, GI-015 waiver): the app is ad-hoc signed
# (`signingIdentity: "-"` in tauri.conf.json) and NOT notarized — no Apple Developer account
# yet. The postflight strips the quarantine flag so `brew install` launches cleanly for the
# trusted cohort; a Developer-ID + notarized build removes the need.
#
# Stanza order and grouping below are `brew style`'s, not this file's preference — the 0.3.0
# cask predates that check and would not pass it. The release job runs `brew style` on what it
# publishes.
#
# `version` and `sha256` are placeholders the release job replaces, and it fails if either
# survives into the published file. They are kept syntactically valid so this file passes
# `brew style` as it stands in the repository.
cask "kinako" do
  version "0.5.2"
  sha256 "c3e7b2c7985fd651b61526bbb94ee799b440b77b6a3b8e96dba81bda34f9540a"

  # The binary is hosted on the PUBLIC homebrew-tap repo's Releases (Homebrew downloads with
  # anonymous curl, which cannot reach a private repo's assets). The Kinako source repo stays
  # private; only the built .app zip is public.
  url "https://github.com/humaninloop-dev/homebrew-tap/releases/download/v#{version}/Kinako-#{version}.zip"
  name "Kinako"
  desc "AI sparring partner for product leaders that becomes their second brain"
  homepage "https://github.com/humaninloop-dev/homebrew-tap"

  # Private dogfood: no public appcast to check against yet.
  livecheck do
    skip "Private dogfood release"
  end

  # Apple Silicon only, by ruling: one Rust target, one artifact, no universal binary.
  # `macos` follows from that rather than being a second decision — no arm64 Mac runs below
  # Big Sur, which is `minimumSystemVersion: "11.0"` in tauri.conf.json. It is written bare
  # because Homebrew 7 itself supports nothing older, and `brew style`'s Homebrew/OSDependsOn
  # cop rejects `macos: :big_sur` as a redundant minimum.
  #
  # `sbx` is a hard runtime dependency (ARCHITECTURE.md). Brew auto-taps docker/tap and
  # installs the binary alongside Kinako. This covers the BINARY ONLY — Docker running +
  # sandbox provisioned + Claude-logged-in are beyond brew's reach and are verified by
  # Kinako's in-app guided Setup readiness probe.
  depends_on arch: :arm64
  depends_on cask: "docker/tap/sbx"
  depends_on :macos

  # No `binary` stanza, deliberately. The `kinako` CLI ships INSIDE the bundle at
  # Contents/MacOS/kinako and is invoked by absolute path from the plugin's hook configuration
  # (`IP-009`). A second install location on PATH would be a second independently-addressed
  # artifact, which is the version skew `IP-009` exists to remove — and it would not help,
  # because the hooks gate on `KINAKO_CLI` being set, not on `kinako` being findable.
  app "Kinako.app"

  # Un-notarized build: strip the quarantine flag Homebrew applies on install so Gatekeeper
  # does not block first launch. Unnecessary once the app is notarized.
  #
  # Homebrew 7 deprecates the free-form `postflight` block for declarative install steps and
  # prints a warning on every command that loads the cask — eight times in one install. Inside
  # a steps block `appdir` is the `{{appdir}}` template, which `run` expands in its arguments.
  postflight_steps do
    run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{appdir}}/Kinako.app"]
  end

  # Uninstall cleanup. Kinako's OWN prefs/support/cache only — keyed to the bundle id. NEVER
  # add ~/.claude or ~/.claude.json here: those are the user's real Claude Code configs, which
  # Kinako never writes, and not ours to zap.
  #
  # The corpus and its backups are deliberately absent: they are the leader's data, they live
  # outside the app-data root by design, and GI-006 forbids losing them silently. The tap
  # README says so plainly, because a leader who zaps deserves to know either way.
  #
  # The "kinako" (lowercase, un-suffixed) entry is the 0.3.0 Flutter store, kept so a zap
  # after upgrading still cleans it up. This version never writes there — it uses the
  # bundle-id path, which Tauri's `app_data_dir()` resolves from the identifier.
  zap trash: [
    "~/Library/Application Support/dev.humaninloop.kinako",
    "~/Library/Application Support/kinako",
    "~/Library/Caches/dev.humaninloop.kinako",
    "~/Library/Preferences/dev.humaninloop.kinako.plist",
    "~/Library/Saved Application State/dev.humaninloop.kinako.savedState",
  ]

  # Kept to what a leader must do next. Caveats print after every install, and a long list of
  # warnings reads as a failed one — the 0.5.0 caveats did exactly that to a tester. Rollback
  # and uninstall live in the tap README, which the last line points to.
  # The paths are interpolated so the settings block pastes as-is: `~` is not expanded there.
  caveats <<~EOS
    To finish setting up Kinako:

      1. Start Docker, then open Kinako and follow guided Setup.
      2. Install the Kinako plugin in Claude Code, and add to ~/.claude/settings.json:

         "env": {
           "KINAKO_CLI": "#{appdir}/Kinako.app/Contents/MacOS/kinako",
           "KINAKO_APP_DATA": "#{Dir.home}/Library/Application Support/dev.humaninloop.kinako"
         }

    Details, rollback and uninstall: https://github.com/humaninloop-dev/homebrew-tap#readme
  EOS
end
