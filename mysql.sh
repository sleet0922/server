#!/bin/bash


if [ "$(id -u)" -ne 0 ]; then
    echo "please use root to run (sudo ./install_mariadb.sh)" >&2
    exit 1
fi


DB_PASSWORD="zyz20050922"
CONFIG_FILE="/etc/mysql/mariadb.conf.d/50-server.cnf"

# 更新系统并安装MariaDB
echo "update package..."
apt update -y

echo "Installing MariaDB server..."
apt install mariadb-server -y


echo "start MariaDB server..."
systemctl start mariadb
systemctl enable mariadb

# 等待服务启动
sleep 5

# 设置root密码（不运行交互式安全脚本）
echo "root password..."
mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
FLUSH PRIVILEGES;
EOF

# 配置允许远程访问
echo "ip contect..."
mysql -u root -p"$DB_PASSWORD" <<EOF
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$DB_PASSWORD' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EXIT;
EOF

# 修改配置文件，允许公网访问
echo "allow ipv46 ask..."
if grep -q "^bind-address" "$CONFIG_FILE"; then
    # 注释掉bind-address行
    sed -i 's/^bind-address/#bind-address/' "$CONFIG_FILE"
else
    # 如果没有找到，则添加注释掉的行
    echo "#bind-address = 127.0.0.1" >> "$CONFIG_FILE"
fi

# 重启MariaDB服务使配置生效
echo "restart MariaDB server..."
systemctl restart mariadb

echo "MariaDB install finish！"
echo "root password: $DB_PASSWORD"
echo "allow * ask"
