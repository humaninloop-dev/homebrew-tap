# humaninloop-dev/homebrew-tap

Kinako — an AI sparring partner for product leaders that becomes their second brain.

Private alpha for a handful of trusted people. Apple Silicon, macOS Big Sur or later. The build is
ad-hoc signed and **not notarized**, so the cask strips the quarantine flag on install to keep
Gatekeeper from blocking first launch.

## Install

```sh
brew tap humaninloop-dev/homebrew-tap
brew trust --cask humaninloop-dev/tap/kinako
brew trust --cask docker/tap/sbx
brew install --cask humaninloop-dev/tap/kinako
```

**Both `trust` lines are required.** Homebrew 6 refuses to load a cask from a third-party tap until
you trust it, and the refusal happens before the cask is read — so the cask's own post-install
notes cannot tell you about it. The second line is not a typo: Kinako depends on the `sbx` cask,
which lives in Docker's tap, and trusting Kinako's tap says nothing about Docker's. Without it the
install stops on `sbx` instead.

`brew install` grants trust to a cask you name **in full**, so the first `trust` line is belt and
braces for the command above — and load-bearing for everything you type afterwards:
`brew install --cask kinako` once the tap is added, `brew info` and `brew fetch` are all refused
without it.

The `brew tap` line is not strictly required — `brew trust` accepts a tap you have not tapped, and
`brew install` taps a fully-qualified name for you. It is kept because tapping first is the
clearer mental model and it costs nothing.

On spellings: Homebrew records the tap as `humaninloop-dev/tap`, dropping the `homebrew-` that the
repository name carries. Both `brew trust` and `brew install` accept either spelling.

## Rolling back

The tap keeps the previous version as a cask of its own, so the binary can go back:

```sh
brew uninstall --cask kinako
brew install --cask humaninloop-dev/homebrew-tap/kinako@0.3.0
```

Two commands, not one: both casks install the same `Kinako.app`, so the newer one has to go first.

**Your corpus does not roll back with it.** A corpus that a newer Kinako has already migrated stays
migrated — an older binary does not undo that, and may not read it. Recovery from a bad migration
runs through Kinako's own snapshot and backup, never through `brew`. Roll the binary back to get
working again, not to get your thinking back.

## After installing

The app is on disk at this point, but it captures nothing yet. Three things are still yours to do.

**1 · Docker must be running.** `sbx` was installed as a dependency, but it needs a Docker engine
— Docker Desktop or otherwise — actually running.

**2 · A provisioned sandbox.** Open Kinako and follow guided Setup. It checks that the sandbox is
running and that Claude is logged in inside it, and names whatever is missing.

**3 · Two environment variables**, without which nothing is captured. Add them under `env` in
`~/.claude/settings.json`, substituting your own home directory:

```json
{
  "env": {
    "KINAKO_CLI": "/Applications/Kinako.app/Contents/MacOS/kinako",
    "KINAKO_APP_DATA": "/Users/<you>/Library/Application Support/dev.humaninloop.kinako"
  }
}
```

Both must be literal absolute paths — a `~` is passed through as the character `~` and the call
fails. Kinako never writes your Claude Code settings, so nothing sets these for you, and **if
either is unset every hook exits 0 and captures nothing.** That is deliberate: a half-configured
Kinako stays out of your way rather than breaking your sessions. It is also silent, which is why
it is worth checking you have actually set them.

Capture also needs the plugin, which installs separately through Claude Code:
[humaninloop-plugins/plugins/kinako](https://github.com/humaninloop-dev/humaninloop-plugins/tree/main/plugins/kinako).
