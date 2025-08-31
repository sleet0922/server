#!/bin/bash
# 1.sh  —— 拍快照
set -euo pipefail

TARGET="/recover/$(date +%F-%H-%M-%S)"
EXCLUDE="/tmp/rsync-exclude.$$"

echo ">>> 开始创建快照：$TARGET"

# 排除伪文件系统
cat > "$EXCLUDE" <<EOF
/dev
/proc
/sys
/run
/tmp
/media
/mnt
/recover
/lost+found
EOF

mkdir -p "$TARGET"
rsync -aAX --numeric-ids --delete --exclude-from="$EXCLUDE" / "$TARGET/"

# 记录元数据
date "+%F %T" > "$TARGET/.snapshot_created"
rm -f "$EXCLUDE"

echo ">>> 快照完成：$TARGET"
