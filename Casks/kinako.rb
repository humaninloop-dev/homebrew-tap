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
cask "kinako" do
  version "0.1.2"
  sha256 "cd4945297af8eca80e729c549449d16d0fec6d31f3ebc759dd8178ed1e0f572a"

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
  zap trash: [
    "~/Library/Application Support/dev.humaninloop.kinako",
    "~/Library/Caches/dev.humaninloop.kinako",
    "~/Library/Preferences/dev.humaninloop.kinako.plist",
    "~/Library/Saved Application State/dev.humaninloop.kinako.savedState",
  ]
end
