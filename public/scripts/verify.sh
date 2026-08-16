#!/usr/bin/env bash
# ============================================================
# verify.sh — 资源完整性校验（主站 public 与本仓库对比）
# 用法:
#   bash scripts/verify.sh             # 快速校验（路径+大小）
#   bash scripts/verify.sh --full      # 完整校验（MD5）
# ============================================================
set -uo pipefail

SRC_PUBLIC="C:/Users/zxabinbina/Desktop/YouzaiWorld/web/YouzaiWorldWebNew/public"
DST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESOURCE_ROOTS=(images fonts medias videos favicon.ico)
FULL="${1:-}"

missing=0
mismatch=0
count=0

for root in "${RESOURCE_ROOTS[@]}"; do
    src="$SRC_PUBLIC/$root"
    [ -e "$src" ] || { echo "[SKIP] $root (源不存在)"; continue; }
    dst="$DST_ROOT/$root"

    if [ -f "$src" ]; then
        files=("$src")
    else
        mapfile -t files < <(find "$src" -type f)
    fi

    for f in "${files[@]}"; do
        rel="${f#"$SRC_PUBLIC"/}"
        target="$DST_ROOT/$rel"
        count=$((count + 1))

        if [ ! -f "$target" ]; then
            echo "[MISSING] $rel"
            missing=$((missing + 1))
            continue
        fi

        if [ "$FULL" = "--full" ]; then
            a=$(md5sum "$f" | cut -d' ' -f1)
            b=$(md5sum "$target" | cut -d' ' -f1)
            if [ "$a" != "$b" ]; then
                echo "[MISMATCH-MD5] $rel"
                mismatch=$((mismatch + 1))
            fi
        else
            a=$(stat -c '%s' "$f")
            b=$(stat -c '%s' "$target")
            if [ "$a" != "$b" ]; then
                echo "[MISMATCH-SIZE] $rel (源 $a / 目标 $b)"
                mismatch=$((mismatch + 1))
            fi
        fi
    done
done

echo "----------------------------------------"
echo "检查 $count 个文件: 缺失 $missing, 不一致 $mismatch"
if [ "$missing" -eq 0 ] && [ "$mismatch" -eq 0 ]; then
    echo "[OK] 资源与主站完全一致"
    exit 0
else
    echo "[FAIL] 存在差异，请运行 sync-assets.sh 同步"
    exit 1
fi
