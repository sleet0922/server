#!/bin/bash
# 3.sh —— 恢复最新快照
set -euo pipefail

# 找最新目录
SNAP=$(ls -1d /recover/2* 2>/dev/null | tail -n1)
[[ -d $SNAP ]] || { echo ">>> 没有找到快照！"; exit 1; }

echo ">>> 即将恢复最新快照：$SNAP"
mount -o remount,rw /
rsync -aAX --numeric-ids --delete \
      --exclude='/dev/*' \
      --exclude='/proc/*' \
      --exclude='/sys/*' \
      --exclude='/run/*' \
      --exclude='/tmp/*' \
      --exclude='/recover' \
      --exclude='/lost+found' \
      "$SNAP/" /

echo ">>> 恢复完成，建议重启"
