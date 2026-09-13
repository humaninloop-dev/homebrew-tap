# Kinako — Homebrew Cask (source of truth; synced to humaninloop-dev/homebrew-tap:Casks/kinako.rb).
#
# Dogfood posture (founder ruling 2026-07-24, GI-031 exception): the app is
# ad-hoc-signed (CODE_SIGN_IDENTITY = "-") and NOT notarized — no Apple Developer
# account yet. The postflight strips the quarantine flag so `brew install` launches
# cleanly for the trusted cohort; a Developer-ID + notarized build removes the need.
#
# On each release, bump `version` and replace `sha256` with the real
# `shasum -a 256 Kinako-<version>.zip` of the uploaded asset. The release
# workflow does both automatically.
cask "kinako@0.3.0" do
  version "0.3.0"
  sha256 "b3a522efb6abc65639e48b5c8f6fed3b1cc570496ee8876d74f5607a51d11070"

  # The binary is hosted on the PUBLIC homebrew-tap repo's Releases (Homebrew
  # downloads with anonymous curl, which cannot reach a private repo's assets).
  # The Kinako source repo stays private; only the built .app zip is public.
  url "https://github.com/humaninloop-dev/homebrew-tap/releases/download/v#{version}/Kinako-#{version}.zip"
  name "Kinako"
  desc "Personal second brain derived from your Claude Code sessions"
  homepage "https://github.com/humaninloop-dev/homebrew-tap"

  # Private dogfood: no public appcast to check against yet.
  livecheck do
    skip "Private dogfood release"
  end

  conflicts_with cask: "kinako"
  depends_on macos: :catalina # a bare symbol means ">= Catalina"; matches MACOSX_DEPLOYMENT_TARGET = 10.15

  # `sbx` is a hard runtime dependency (ARCHITECTURE.md). Brew auto-taps docker/tap
  # and installs the binary alongside Kinako. This covers the BINARY ONLY — Docker
  # running + sandbox provisioned + Claude-logged-in are beyond brew's reach and are
  # verified by Kinako's in-app guided Setup readiness probe (GI-005/GI-006).
  depends_on cask: "docker/tap/sbx"

  app "Kinako.app"

  caveats <<~EOS
    `sbx` was installed as a dependency. Kinako still needs a running Docker
    sandbox to derive knowledge:
      1. Install Docker (Desktop or engine) and make sure it is running.
      2. Open Kinako and follow guided Setup — it checks the sandbox is running
         and Claude is logged in, and tells you exactly what is missing.
  EOS

  # Un-notarized build: strip the quarantine flag Homebrew applies on install so
  # Gatekeeper does not block first launch. Unnecessary once the app is notarized.
  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/Kinako.app"]
  end

  # Uninstall cleanup. Kinako's OWN prefs/support/cache only — keyed to the bundle
  # id. NEVER add ~/.claude or ~/.claude.json here: those are the user's real Claude
  # Code configs (Kinako merges into them non-destructively, GI-032), not ours to zap.
  #
  # The "kinako" (lowercase, un-suffixed) entry is the one that matters and was
  # MISSING until MVP-H1: LocalStoreLocation.base() writes to
  # `~/Library/Application Support/kinako`, NOT to the bundle-id path the other
  # entries use. Every dogfood install to date has therefore left its whole store
  # behind on `brew uninstall --zap`. That directory now also holds the installed
  # `bin/kinako-hook` (D-H2), so without this line an uninstall would leave a live
  # hook binary on disk with no app.
  zap trash: [
    "~/Library/Application Support/kinako",
    "~/Library/Application Support/dev.humaninloop.kinako",
    "~/Library/Caches/dev.humaninloop.kinako",
    "~/Library/Preferences/dev.humaninloop.kinako.plist",
    "~/Library/Saved Application State/dev.humaninloop.kinako.savedState",
  ]
end
