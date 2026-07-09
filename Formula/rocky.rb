class Rocky < Formula
  desc "Floating pixel-cat desktop pet for Claude Code"
  homepage "https://github.com/KetanSomvanshi/rocky"
  url "https://github.com/KetanSomvanshi/rocky/archive/refs/tags/v1.1.0.tar.gz"
  sha256 "f01fc143c2e0b6c17d778368c2be2453773e18919eec7d5623ac9c0d5504fb82"
  license "MIT"
  head "https://github.com/KetanSomvanshi/rocky.git", branch: "main"

  depends_on :macos

  def install
    # Native Swift app; compiled locally, so no Gatekeeper prompt.
    system "xcrun", "swiftc", "-O", "RockyCore.swift", "main.swift", "-o", "rocky"
    bin.install "rocky"

    # Sources kept for the optional screen saver + the hook + wiring scripts.
    libexec.install "rocky-hook.py"
    libexec.install "scripts/wire-hooks.py"
    libexec.install "RockyCore.swift"
    (libexec/"screensaver").install "screensaver/RockySaverView.swift"
    (libexec/"screensaver").install "screensaver/Info.plist"

    (bin/"rocky-setup").write <<~SH
      #!/bin/bash
      exec python3 "#{libexec}/wire-hooks.py" wire "python3 #{libexec}/rocky-hook.py"
    SH
    (bin/"rocky-teardown").write <<~SH
      #!/bin/bash
      exec python3 "#{libexec}/wire-hooks.py" unwire
    SH

    # Build & install the universal screen-saver bundle on demand (Homebrew
    # shouldn't write to ~/Library/Screen Savers itself).
    (bin/"rocky-screensaver").write <<~SH
      #!/bin/bash
      set -e
      B="$(mktemp -d)/Rocky.saver"; mkdir -p "$B/Contents/MacOS"
      cp "#{libexec}/screensaver/Info.plist" "$B/Contents/Info.plist"
      for arch in arm64 x86_64; do
        xcrun swiftc -O -target "$arch-apple-macos12.0" -module-name RockySaver \
          -framework ScreenSaver -emit-library -Xlinker -bundle \
          -o "$B/Contents/MacOS/Rocky.$arch" \
          "#{libexec}/RockyCore.swift" "#{libexec}/screensaver/RockySaverView.swift"
      done
      lipo -create "$B/Contents/MacOS/Rocky.arm64" "$B/Contents/MacOS/Rocky.x86_64" \
        -output "$B/Contents/MacOS/Rocky"
      rm -f "$B/Contents/MacOS/Rocky.arm64" "$B/Contents/MacOS/Rocky.x86_64"
      DEST="$HOME/Library/Screen Savers/Rocky.saver"; rm -rf "$DEST"; cp -R "$B" "$DEST"
      echo "Installed Rocky.saver — pick Rocky in System Settings > Screen Saver."
    SH

    chmod 0755, bin/"rocky-setup"
    chmod 0755, bin/"rocky-teardown"
    chmod 0755, bin/"rocky-screensaver"
  end

  service do
    run [opt_bin/"rocky"]
    keep_alive true
    run_type :immediate
    log_path "#{var}/log/rocky.log"
    error_log_path "#{var}/log/rocky.log"
  end

  def caveats
    <<~EOS
      One-time setup — connect Rocky to Claude Code:
        rocky-setup

      Start Rocky now and at login:
        brew services start rocky

      Optional screen saver (shows your sessions while the Mac is idle):
        rocky-screensaver     # then pick Rocky in System Settings > Screen Saver

      Open a fresh Claude Code session (or run /hooks) so the hooks load.
      Disconnect the hooks later with: rocky-teardown
    EOS
  end

  test do
    assert_path_exists bin/"rocky"
    assert_path_exists libexec/"rocky-hook.py"
    assert_path_exists libexec/"screensaver/RockySaverView.swift"
  end
end
