class Magicterminal < Formula
  desc "Grep for your team's terminal logs."
  homepage "https://github.com/prodgai/magic_terminal_desktop"
  url "git@github.com:prodgai/magic_terminal_desktop.git", using: :git, tag: "v1.0.0"
  version "v1.0.0"
  license "MIT"

  def install
    system "git", "checkout", "#{version}"
    system "./install.sh"
  end

  test do
    # Test instructions go here
    # Example:
    # system "#{bin}/myproject", "--version"
  end
end