#!/bin/bash
set -euo pipefail

# 找最新目录
SNAP=$(ls -1d /recover/2* 2>/dev/null | tail -n1)
[[ -d $SNAP ]] || { echo ">>> no shot！"; exit 1; }

echo ">>> it will be recovered：$SNAP"
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

echo ">>> suggest restart"
