cat >/etc/sysctl.d/99-custom.conf <<'EOF'
# 更积极回收文件缓存
vm.vfs_cache_pressure=200

# 尽量少用 swap
vm.swappiness=5

# 减少脏页缓存
vm.dirty_background_ratio=5
vm.dirty_ratio=15

# 保留空闲内存
vm.min_free_kbytes=65536

# 更积极后台回收
vm.watermark_scale_factor=125
EOF

sysctl --system
