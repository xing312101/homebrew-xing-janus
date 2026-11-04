# Xing Janus（xj）的 Homebrew formula：brew tap xing312101/xing-janus && brew trust --formula xing312101/xing-janus/xj && brew install xj
# url、sha256、version 這三行由 .github/workflows/update.yml 照 xing312101/xing-janus-releases 最新的公開 release 更新
# （先用 minisign 驗過簽章，.github/update-formula.sh），不用手改。
# 這個檔案由開發 repo 的 scripts/homebrew/make-tap.sh 產生。tap 的檔案照 tap 的 LICENSE（BSD-2-Clause）；
# xj 本身照壓縮檔裡的使用條款（下面的 license）
class Xj < Formula
  desc "Coding agent in your terminal, behind a permission layer and an OS sandbox"
  homepage "https://github.com/xing312101/xing-janus-releases"
  url "https://github.com/xing312101/xing-janus-releases/releases/download/v0.1.3/xj-0.1.3-darwin.tar.gz"
  sha256 "53a7b4d28c1df0b15b00bff074b60289c5fd143484478bb7883297153b15f50b"
  version "0.1.3"
  # 使用條款（壓縮檔裡的 LICENSE）不是開源授權
  license :cannot_represent

  # Linux 的沙盒還要從 npm 裝 sandbox-runtime（apply-seccomp）：照 releases 頁面的步驟裝
  depends_on :macos
  depends_on "node"
  depends_on "ripgrep"

  def install
    libexec.install Dir["*"]
    # 啟動器照 PATH 找 node：換成 brew 的 node（nvm 切到哪一版都不影響 xj 自己）。PATH 不動：
    # 你專案裡的指令照舊用 PATH 上的 node
    inreplace libexec/"xj", "node=$(command -v node || true)", "node=#{Formula["node"].opt_bin}/node"
    bin.install_symlink libexec/"xj"
  end

  test do
    assert_match "xing-janus #{version}", shell_output("#{bin}/xj --version")
  end
end
