#!/bin/sh
# 照 xing312101/xing-janus-releases 最新的公開 release 更新 Formula/xj.rb（tap repo 的 .github/workflows/update.yml 跑它）。
# brew 只核對 SHA-256、不驗簽章，所以更新之前先用寫死的公鑰驗 minisign 簽章：releases repo 被改了的話，
# 換掉的壓縮檔驗不過，formula 不跟著換。簽章的附註要是那個版本、那個檔名（拿別的版本、別的檔的簽章頂替也不行），
# 版本只能往上（降版會裝回有已知漏洞的舊版）。
# 這個檔案由開發 repo 的 scripts/homebrew/make-tap.sh 產生
set -eu
repo=xing312101/xing-janus-releases
pub=RWR8QI6mlwg4yrxuGNlQojUwQGy82MQyHSPAbSMdvTn1+6CEQYe9OWPd
formula=Formula/xj.rb

die() {
  printf '✗ %s\n' "$*" >&2
  exit 1
}
sha256() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | cut -d ' ' -f 1; else shasum -a 256 "$1" | cut -d ' ' -f 1; fi
}

tag=$(gh release view --repo "$repo" --json tagName --jq .tagName)
new=${tag#v}
printf '%s' "$new" | grep -qxE '[0-9]+\.[0-9]+\.[0-9]+' || die "不認得的版本：${tag}"
cur=$(sed -n 's/^  version "\(.*\)"$/\1/p' "$formula")
if [ "$new" = "$cur" ]; then
  printf '已經是 %s\n' "$cur"
  exit 0
fi
newest=$(printf '%s\n%s\n' "$cur" "$new" | sort -t . -k 1,1n -k 2,2n -k 3,3n | tail -n 1)
[ "$newest" = "$new" ] || die "最新的 release（${new}）比 formula 的（${cur}）舊：不更新"

name=xj-${new}-darwin.tar.gz
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
gh release download "$tag" --repo "$repo" --dir "$work" --pattern "$name" --pattern "$name.minisig"
out=$(minisign -V -P "$pub" -m "$work/$name") || die "${name} 的簽章驗不過：不更新"
printf '%s\n' "$out" | grep -qxF "Trusted comment: xing-janus $tag $name" || die "簽章的附註不是 ${tag} 的 ${name}：不更新"
sum=$(sha256 "$work/$name")

url=https://github.com/${repo}/releases/download/${tag}/${name}
sed -e "s|^  url \".*\"\$|  url \"$url\"|" -e "s|^  sha256 \".*\"\$|  sha256 \"$sum\"|" -e "s|^  version \".*\"\$|  version \"$new\"|" "$formula" >"$work/xj.rb"
grep -qxF "  version \"$new\"" "$work/xj.rb" && grep -qxF "  sha256 \"$sum\"" "$work/xj.rb" && grep -qxF "  url \"$url\"" "$work/xj.rb" || die "formula 的 url、sha256、version 沒改到"
mv "$work/xj.rb" "$formula"

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add "$formula"
git commit -q -m "xj $new"
# 明確推到 main（tap 的預設分支）：不靠 checkout 有沒有設上游分支
git push -q origin HEAD:main
printf '更新到 %s\n' "$new"
