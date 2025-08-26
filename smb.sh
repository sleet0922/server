#!/bin/bash

# 警告：此配置允许通过SMB以root权限修改系统所有文件，存在严重安全风险！
echo "=============================================="
echo "it is dangerous"
echo "=============================================="
read -p "Are you sure？(press yes)：" confirm
if [ "$confirm" != "yes" ]; then
    echo "exit"
    exit 1
fi

# 安装SMB服务
echo "start installing SMB..."
apt update && apt install -y samba samba-common-bin

# 备份原有SMB配置（如果存在）
cp /etc/samba/smb.conf /etc/samba/smb.conf.bak$(date +%Y%m%d%H%M%S)

# 创建自定义配置文件（按要求修改为root权限）
echo "config SMB..."
tee /etc/samba/smb.conf > /dev/null << 'EOF'
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


[share]
path = /
browseable = yes
writable = yes
guest ok = yes
guest only = yes
create mask = 0777
directory mask = 0777
force user = root 
# 强制使用root用户（原配置为www-data，已修改）
force group = root  
# 强制使用root组（原配置为www-data，已修改）
EOF

# 重启SMB服务
echo "restart SMB..."
systemctl restart smbd nmbd

# 显示服务状态
echo "SMB status："
systemctl status smbd --no-pager

echo "=============================================="
echo "All the things are ok!"
echo "=============================================="
