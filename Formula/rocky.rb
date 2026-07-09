class Rocky < Formula
  desc "Floating pixel-cat desktop pet for Claude Code"
  homepage "https://github.com/KetanSomvanshi/rocky"
  url "https://github.com/KetanSomvanshi/rocky/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "c4f597e2a1d471f8ab7e3f6e078785b84875c7d0cdf588200dc4f7158fbc411c"
  license "MIT"
  head "https://github.com/KetanSomvanshi/rocky.git", branch: "main"

  depends_on :macos

  def install
    # Single-file native Swift app; compiled locally, so no Gatekeeper prompt.
    system "xcrun", "swiftc", "-O", "main.swift", "-o", "rocky"
    bin.install "rocky"
    libexec.install "rocky-hook.py"
    libexec.install "scripts/wire-hooks.py"

    # Helper commands to connect/disconnect Rocky's Claude Code hooks. They
    # point at the hook script inside libexec and merge idempotently into
    # ~/.claude/settings.json (leaving any other hooks untouched).
    (bin/"rocky-setup").write <<~SH
      #!/bin/bash
      exec python3 "#{libexec}/wire-hooks.py" wire "python3 #{libexec}/rocky-hook.py"
    SH
    (bin/"rocky-teardown").write <<~SH
      #!/bin/bash
      exec python3 "#{libexec}/wire-hooks.py" unwire
    SH
    chmod 0755, bin/"rocky-setup"
    chmod 0755, bin/"rocky-teardown"
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

      Open a fresh Claude Code session (or run /hooks) so the hooks load.
      Disconnect the hooks later with:
        rocky-teardown
    EOS
  end

  test do
    assert_path_exists bin/"rocky"
    assert_path_exists libexec/"rocky-hook.py"
  end
end
