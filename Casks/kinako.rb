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
  version "0.5.0"
  sha256 "8b603003afd7c1551f488733f4d887fe57ec7d89b9e439cd555d7b30a4c206cb"

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
  # Big Sur, so the 0.3.0 cask's inherited `:catalina` would be a false claim, not a looser
  # one. It matches `minimumSystemVersion: "11.0"` in tauri.conf.json. A bare symbol already
  # means ">= Big Sur" — which is what the 0.3.0 cask's own comment said about `:catalina`,
  # and what `brew style`'s Homebrew/OSDependsOn cop enforces.
  #
  # `sbx` is a hard runtime dependency (ARCHITECTURE.md). Brew auto-taps docker/tap and
  # installs the binary alongside Kinako. This covers the BINARY ONLY — Docker running +
  # sandbox provisioned + Claude-logged-in are beyond brew's reach and are verified by
  # Kinako's in-app guided Setup readiness probe.
  depends_on arch: :arm64
  depends_on cask: "docker/tap/sbx"
  depends_on macos: :big_sur

  # No `binary` stanza, deliberately. The `kinako` CLI ships INSIDE the bundle at
  # Contents/MacOS/kinako and is invoked by absolute path from the plugin's hook configuration
  # (`IP-009`). A second install location on PATH would be a second independently-addressed
  # artifact, which is the version skew `IP-009` exists to remove — and it would not help,
  # because the hooks gate on `KINAKO_CLI` being set, not on `kinako` being findable.
  app "Kinako.app"

  # Un-notarized build: strip the quarantine flag Homebrew applies on install so Gatekeeper
  # does not block first launch. Unnecessary once the app is notarized.
  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/Kinako.app"]
  end

  # Uninstall cleanup. Kinako's OWN prefs/support/cache only — keyed to the bundle id. NEVER
  # add ~/.claude or ~/.claude.json here: those are the user's real Claude Code configs
  # (Kinako merges into them non-destructively), not ours to zap.
  #
  # The corpus and its backups are deliberately absent: they are the leader's data, they live
  # outside the app-data root by design, and GI-006 forbids losing them silently. The caveat
  # below says so plainly, because a leader who zaps deserves to know either way.
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

  caveats <<~EOS
    `sbx` was installed as a dependency. Kinako still needs a running Docker sandbox to
    derive knowledge:
      1. Install Docker (Desktop or engine) and make sure it is running.
      2. Open Kinako and follow guided Setup — it checks the sandbox is running and Claude
         is logged in, and tells you exactly what is missing.

    Capture from your Claude Code sessions does not start until you set two variables.
    Nothing sets them for you: Kinako does not write your harness store. Add to
    ~/.claude/settings.json, substituting your own home directory:

      "env": {
        "KINAKO_CLI": "/Applications/Kinako.app/Contents/MacOS/kinako",
        "KINAKO_APP_DATA": "/Users/<you>/Library/Application Support/dev.humaninloop.kinako"
      }

    Both must be literal absolute paths — a `~` in either value is passed through as the
    character `~` and the call fails. Full instructions, including the plugin install:
    https://github.com/humaninloop-dev/humaninloop-plugins/tree/main/plugins/kinako

    Upgrading from 0.3.0: this is a new application on the same bundle id, so `brew upgrade`
    replaces it in place. It creates a fresh corpus and reads nothing from the 0.3.0 store
    at ~/Library/Application Support/kinako, which is left where it is and is inert.

    Rolling back to an earlier version takes TWO commands, not one: both casks install the
    same Kinako.app, so the newer one has to go first.

      brew uninstall --cask kinako
      brew install --cask humaninloop-dev/homebrew-tap/kinako@<previous version>

    Rolling the app back does NOT roll your corpus back. A corpus a newer version has
    migrated stays migrated; recovery from that runs through Kinako's own snapshot and
    backup, never through brew.

    `brew uninstall --zap` removes Kinako's own records only. It does NOT remove your corpus
    or its backups — by default ~/Documents/Kinako Corpus and the backups folder beside it —
    so uninstalling never deletes your thinking. It DOES discard any captured turns still
    sitting in the spool that the app has not swept yet.
  EOS
end
