#!/bin/bash

# 警告：此配置允许通过SMB以root权限修改系统所有文件，存在严重安全风险！
echo "=============================================="
echo "警告：此操作极度危险，仅用于测试，测试后请立即清理！"
echo "=============================================="
read -p "确认继续？(输入yes继续，其他键退出)：" confirm
if [ "$confirm" != "yes" ]; then
    echo "已取消操作"
    exit 1
fi

# 安装SMB服务
echo "开始安装SMB服务..."
sudo apt update && sudo apt install -y samba samba-common-bin

# 备份原有SMB配置（如果存在）
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.bak$(date +%Y%m%d%H%M%S)

# 创建自定义配置文件（按要求修改为root权限）
echo "配置SMB文件..."
sudo tee /etc/samba/smb.conf > /dev/null << 'EOF'
[global]
workgroup = WORKGROUP
server string = Web Directory Share
security = user
map to guest = Bad User
guest account = nobody
socket options = TCP_NODELAY SO_RCVBUF=65536 SO_SNDBUF=65536
read raw = yes
write raw = yes
getwd cache = yes


[MyWebFiles]
path = /
browseable = yes
writable = yes
guest ok = yes
guest only = yes
create mask = 0777
directory mask = 0777
force user = root  # 强制使用root用户（原配置为www-data，已修改）
force group = root  # 强制使用root组（原配置为www-data，已修改）
EOF

# 重启SMB服务
echo "重启SMB服务..."
sudo systemctl restart smbd nmbd

# 显示服务状态
echo "SMB服务状态："
sudo systemctl status smbd --no-pager

echo "=============================================="
echo "配置完成！风险提示："
echo "1. 此时通过网络可以root权限修改系统所有文件"
echo "2. 测试完成后请执行：sudo systemctl stop smbd nmbd"
echo "3. 并恢复配置：sudo mv /etc/samba/smb.conf.bak* /etc/samba/smb.conf"
echo "=============================================="
