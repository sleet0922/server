#!/bin/bash

# 确保脚本以root权限运行
if [ "$(id -u)" -ne 0 ]; then
    echo "请使用root权限运行此脚本 (sudo ./install_mariadb.sh)" >&2
    exit 1
fi

# 定义变量
DB_PASSWORD="zyz20050922"
CONFIG_FILE="/etc/mysql/mariadb.conf.d/50-server.cnf"

# 更新系统并安装MariaDB
echo "更新系统包列表..."
apt update -y

echo "安装MariaDB服务器..."
apt install mariadb-server -y

# 启动服务并设置开机自启
echo "启动MariaDB服务..."
systemctl start mariadb
systemctl enable mariadb

# 等待服务启动
sleep 5

# 设置root密码（不运行交互式安全脚本）
echo "配置root密码..."
mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
FLUSH PRIVILEGES;
EOF

# 配置允许远程访问
echo "配置远程访问权限..."
mysql -u root -p"$DB_PASSWORD" <<EOF
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$DB_PASSWORD' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EXIT;
EOF

# 修改配置文件，允许公网访问
echo "修改配置文件以允许公网访问..."
if grep -q "^bind-address" "$CONFIG_FILE"; then
    # 注释掉bind-address行
    sed -i 's/^bind-address/#bind-address/' "$CONFIG_FILE"
else
    # 如果没有找到，则添加注释掉的行
    echo "#bind-address = 127.0.0.1" >> "$CONFIG_FILE"
fi

# 重启MariaDB服务使配置生效
echo "重启MariaDB服务..."
systemctl restart mariadb

echo "MariaDB安装和配置完成！"
echo "root用户密码已设置为: $DB_PASSWORD"
echo "已允许从公网任何IP访问"
