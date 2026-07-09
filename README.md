# 🍺 homebrew-tap

Homebrew tap for [Rocky](https://github.com/KetanSomvanshi/rocky) — a floating
pixel-cat desktop pet for Claude Code.

## Install

```bash
brew install ketansomvanshi/tap/rocky
```

Then connect it to Claude Code and start it at login:

```bash
rocky-setup                 # merge Rocky's hooks into ~/.claude/settings.json
brew services start rocky   # launch now + at login
```

Open a fresh Claude Code session (or run `/hooks`) so the hooks load.

- Update:    `brew upgrade rocky`
- Stop:      `brew services stop rocky`
- Uninstall: `rocky-teardown && brew services stop rocky && brew uninstall rocky`

Rocky is a single ~190 KB native Swift binary. Homebrew compiles it locally, so
there's no Gatekeeper "unidentified developer" prompt.
