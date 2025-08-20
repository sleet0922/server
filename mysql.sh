#!/bin/bash

# 注意：
# 1. 脚本需要 root 权限运行（使用 sudo 执行）
# 2. 此配置允许任意 IP 以 root 用户访问，生产环境请谨慎使用

# 检查是否以 root 权限运行
if [ "$(id -u)" -ne 0 ]; then
    echo "错误：请使用 sudo 或 root 权限运行此脚本"
    exit 1
fi

# 变量设置（使用统一的用户名和密码）
MYSQL_ROOT_PWD="zyz20050922"  # MySQL root 密码
REMOTE_ACCESS_PWD="zyz20050922"   # 远程访问密码
MYSQL_USER="root"              # 统一使用 root 用户

# 步骤0：备份原始配置文件
echo "正在备份原始 MySQL 配置文件..."
CONFIG_FILE="/etc/mysql/mysql.conf.d/mysqld.cnf"
BACKUP_FILE="/etc/mysql/mysql.conf.d/mysqld.cnf.backup.$(date +%Y%m%d%H%M%S)"
cp "$CONFIG_FILE" "$BACKUP_FILE"
echo "配置文件已备份到: $BACKUP_FILE"

# 步骤1：完全替换 MySQL 配置文件
echo "正在替换 MySQL 配置文件..."
cat > "$CONFIG_FILE" << 'EOF'
[mysqld]
user            = mysql
pid-file        = /var/run/mysqld/mysqld.pid
socket          = /var/run/mysqld/mysqld.sock
port            = 3306
basedir         = /usr
datadir         = /var/lib/mysql
tmpdir          = /tmp
lc-messages-dir = /usr/share/mysql
skip-external-locking

# 允许远程连接
bind-address            = 0.0.0.0

# 连接设置
max_connections        = 100
connect_timeout        = 5
wait_timeout           = 600
max_allowed_packet     = 16M
thread_cache_size      = 128

# 日志设置
log_error = /var/log/mysql/error.log
slow_query_log = 1
slow_query_log_file = /var/log/mysql/mysql-slow.log
long_query_time = 2

# InnoDB 设置
innodb_buffer_pool_size = 128M
innodb_log_file_size    = 64M
innodb_file_per_table   = 1
innodb_flush_log_at_trx_commit = 2

# 其他优化
key_buffer_size         = 16M
myisam-recover-options  = BACKUP
EOF

echo "MySQL 配置文件已替换完成"

# 步骤2：重启 MySQL 服务
echo "正在重启 MySQL 服务..."
systemctl restart mysql
if [ $? -ne 0 ]; then
    echo "错误：MySQL 重启失败，请检查配置文件"
    echo "正在恢复备份文件..."
    cp "$BACKUP_FILE" "$CONFIG_FILE"
    systemctl restart mysql
    exit 1
fi

# 等待MySQL服务完全启动
sleep 3

# 步骤3：配置 MySQL 远程访问权限
echo "正在配置 MySQL 权限..."
mysql -u root -p"$MYSQL_ROOT_PWD" -e "
-- 确保 root 用户存在并使用统一密码
ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PWD';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;

-- 创建允许远程连接的 root 用户
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '$REMOTE_ACCESS_PWD';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;

-- 刷新权限
FLUSH PRIVILEGES;
"

if [ $? -ne 0 ]; then
    echo "错误：MySQL 权限配置失败，请检查 root 密码是否正确"
    echo "如果这是首次运行，MySQL root 密码可能还未设置，请先手动设置密码后再运行此脚本"
    exit 1
fi

# 步骤4：开放防火墙 3306 端口
echo "正在配置防火墙..."
if command -v ufw &> /dev/null && ufw status | grep -q "active"; then
    ufw allow 3306/tcp
    ufw reload
    echo "UFW 防火墙已开放 3306 端口"
elif command -v firewall-cmd &> /dev/null; then
    firewall-cmd --add-port=3306/tcp --permanent
    firewall-cmd --reload
    echo "FirewallD 防火墙已开放 3306 端口"
else
    echo "警告：未检测到活跃的 ufw 或 firewalld，请确保服务器安全组/防火墙已开放 3306 端口"
fi

# 步骤5：显示连接信息
SERVER_IP=$(hostname -I | awk '{print $1}')
echo ""
echo "================================================"
echo "配置完成！MySQL 已允许远程访问"
echo "================================================"
echo "连接信息："
echo "主机: $SERVER_IP 或 您的服务器公网IP"
echo "端口: 3306"
echo "用户名: $MYSQL_USER"
echo "密码: $REMOTE_ACCESS_PWD"
echo ""
echo "测试命令: mysql -h $SERVER_IP -u $MYSQL_USER -p"
echo "================================================"
echo "注意：此配置安全性较低，仅适用于测试环境！"
echo "================================================"
