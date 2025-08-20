#!/bin/bash

# MySQL安装配置脚本
# 配置要求：允许远程访问、root密码zyz20050922、支持IPv6

set -e  # 遇到错误立即退出

# 颜色输出设置
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印彩色信息
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否以root权限运行
if [ "$EUID" -ne 0 ]; then
    print_error "请使用root权限运行此脚本"
    exit 1
fi

# 安装MySQL最新稳定版
install_mysql() {
    print_info "开始安装MySQL..."
    
    # 下载并安装MySQL APT仓库
    wget https://dev.mysql.com/get/mysql-apt-config_0.8.28-1_all.deb
    dpkg -i mysql-apt-config_0.8.28-1_all.deb
    apt-get update
    
    # 安装MySQL服务器
    apt-get install -y mysql-server
    
    print_info "MySQL安装完成"
}

# 配置MySQL
configure_mysql() {
    print_info "开始配置MySQL..."
    
    # 启动MySQL服务
    systemctl start mysql
    systemctl enable mysql
    
    # 获取初始临时密码
    temp_password=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}')
    
    if [ -z "$temp_password" ]; then
        print_warning "未找到临时密码，可能已经初始化过"
        # 尝试使用空密码登录配置
        mysql -u root <<-EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'zyz20050922';
FLUSH PRIVILEGES;
EOF
    else
        # 使用临时密码登录并修改密码
        mysql --connect-expired-password -u root -p"$temp_password" <<-EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'zyz20050922';
FLUSH PRIVILEGES;
EOF
    fi
    
    # 创建配置文件允许远程访问和IPv6
    cat > /etc/mysql/conf.d/custom.cnf << EOF
[mysqld]
bind-address = ::
skip-name-resolve

[mysql]
bind-address = ::
EOF
    
    # 配置允许远程root访问
    mysql -u root -pzyz20050922 <<-EOF
USE mysql;
UPDATE user SET host='%' WHERE user='root';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'zyz20050922' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF
    
    # 重启MySQL服务使配置生效
    systemctl restart mysql
    
    print_info "MySQL配置完成"
}

# 防火墙配置（如果启用了防火墙）
configure_firewall() {
    if command -v ufw >/dev/null 2>&1; then
        print_info "配置UFW防火墙..."
        ufw allow mysql
    fi
    
    if command -v firewall-cmd >/dev/null 2>&1; then
        print_info "配置firewalld..."
        firewall-cmd --add-service=mysql --permanent
        firewall-cmd --reload
    fi
}

# 验证安装
verify_installation() {
    print_info "验证MySQL安装..."
    
    # 检查MySQL服务状态
    if systemctl is-active --quiet mysql; then
        print_info "MySQL服务正在运行"
    else
        print_error "MySQL服务未运行"
        exit 1
    fi
    
    # 测试连接
    if mysql -u root -pzyz20050922 -e "SELECT @@version;" >/dev/null 2>&1; then
        print_info "MySQL连接测试成功"
    else
        print_error "MySQL连接测试失败"
        exit 1
    fi
    
    # 检查IPv6监听
    if netstat -tuln | grep -E ':3306.*LISTEN'; then
        print_info "MySQL正在监听3306端口"
    else
        print_error "MySQL未监听3306端口"
    fi
    
    # 显示MySQL版本
    mysql_version=$(mysql -u root -pzyz20050922 -e "SELECT @@version;" -s)
    print_info "安装的MySQL版本: $mysql_version"
}

# 显示连接信息
show_connection_info() {
    print_info "============================================"
    print_info "MySQL安装配置完成！"
    print_info "用户名: root"
    print_info "密码: zyz20050922"
    print_info "支持IPv6连接"
    print_info "允许远程访问"
    print_info "连接示例: mysql -h <服务器IP> -u root -p"
    print_info "============================================"
}

# 主执行函数
main() {
    print_info "开始MySQL安装和配置过程..."
    
    # 更新系统包
    apt-get update
    apt-get upgrade -y
    
    # 安装依赖
    apt-get install -y wget gnupg
    
    # 执行安装和配置
    install_mysql
    configure_mysql
    configure_firewall
    verify_installation
    show_connection_info
    
    print_info "所有操作已完成！"
}

# 执行主函数
main "$@"
