#!/bin/bash
set -e  # 任何命令失败立即退出脚本

# 检查是否为root权限
if [ "$(id -u)" -ne 0 ]; then
    echo "错误：请使用root权限执行（sudo ./server_setup.sh）"
    exit 1
fi

# 1. 替换SSH配置文件
echo "===== 替换SSH配置 ====="
if [ -f "./sshd_config" ]; then
    cp ./sshd_config /etc/ssh/sshd_config
    echo "SSH配置替换完成"
else
    echo "错误：当前目录未找到sshd_config文件"
    exit 1
fi

# 2. 安装并配置Nginx
echo -e "\n===== 安装配置Nginx ====="
apt update -y
apt install nginx -y

# 备份默认Nginx配置
cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak

# 写入新的Nginx配置
cat > /etc/nginx/sites-available/default << 'EOF'
# HTTP 81端口重定向到HTTPS 444端口
# 同时监听IPv4和IPv6
server {
    listen 81;
    listen [::]:81;
    server_name zyz0922.cn;
    
    # 永久重定向到HTTPS（带端口444）
    return 301 https://$host:444$request_uri;
    
    # IPv6专用访问日志（可选）
    access_log /var/log/nginx/access_ipv6.log;
}

# HTTPS 444端口核心服务配置
# 同时监听IPv4和IPv6
server {
    listen 444 ssl http2;
    listen [::]:444 ssl http2;
    server_name zyz0922.cn;
    
    # SSL证书配置
    ssl_certificate /ssl/zyz0922.cn.pem;         # 证书文件（公钥）
    ssl_certificate_key /ssl/zyz0922.cn.key;     # 私钥文件
    
    # SSL安全优化配置
    ssl_protocols TLSv1.2 TLSv1.3;                           # 支持的TLS版本
    ssl_prefer_server_ciphers on;                             # 优先使用服务器加密套件
    ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384";
    ssl_session_cache shared:SSL:10m;                         # 共享SSL会话缓存
    ssl_session_timeout 1d;                                   # 会话超时时间
    ssl_session_tickets off;                                  # 禁用会话票据
    
    # HSTS配置（增强安全性，可选）
    # 注意：启用后浏览器将强制使用HTTPS，需确保HTTPS服务正常
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # 网站根目录与默认首页
    root /var/www/html;
    index index.html;
    
    # 静态文件缓存配置
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|html)$ {
        expires max;           # 缓存有效期最大化
        access_log off;        # 关闭静态文件访问日志
    }
    
    # 前端路由支持（单页应用刷新无404）
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # 后端API代理配置
    location /api/ {
        proxy_pass http://localhost:8081;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # IPv6地址转发支持
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
    }
    
    # WebSocket协议支持
    location /ws/ {
        proxy_pass http://localhost:8081;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_read_timeout 86400;  # 延长超时时间（24小时）
    }
    
    # ISO文件下载配置
    location /usb/ {
        autoindex on;  # 允许显示目录列表
    }
    
    # IPv6专用错误页面（可选）
        error_page 404 /404_ipv6.html;
        location = /404_ipv6.html {
        root /var/www/html/errors;
        internal;
    }
}
EOF

# 创建Nginx所需目录和文件
mkdir -p /ssl /var/www/html /var/www/html/errors
echo "<h1>Welcome to zyz0922.cn</h1>" > /var/www/html/index.html
echo "<h1>404 Not Found (IPv6)</h1>" > /var/www/html/errors/404_ipv6.html

# 启动Nginx并设置开机自启
systemctl enable nginx --now
nginx -t && systemctl restart nginx
echo "Nginx配置完成"

# 3. 安装配置ddns-go
echo -e "\n===== 安装配置ddns-go ====="
if [ -f "./ddns-go_linux64.tar.gz" ]; then
    # 解压并部署
    tar -zxvf ./ddns-go_linux64.tar.gz
    mkdir -p /usr/local/ddns-go
    cp ./ddns-go /usr/local/ddns-go/
    
    # 创建服务文件
    cat > /etc/systemd/system/ddns-go.service << 'EOF'
[Unit]
Description=The DDNS-GO Process Manager
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/ddns-go/ddns-go -c /usr/local/ddns-go/ddns_go_config.yaml
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    # 启动服务
    systemctl daemon-reload
    systemctl enable ddns-go --now
    echo "ddns-go配置完成"
else
    echo "错误：当前目录未找到ddns-go_linux64.tar.gz文件"
    exit 1
fi

# 4. 开放防火墙端口（如果使用ufw）
if command -v ufw &> /dev/null; then
    echo -e "\n===== 配置防火墙 ====="
    ufw allow 22/tcp          # SSH
    ufw allow 81/tcp          # HTTP重定向
    ufw allow 444/tcp         # HTTPS服务
    ufw allow 9876/tcp        # ddns-go管理界面（配置完成后可关闭）
    ufw reload
    echo "防火墙端口配置完成"
fi

echo -e "\n===== 所有配置已完成 ====="
echo "请确认："
echo "1. SSL证书已放置在 /ssl/zyz0922.cn.pem 和 /ssl/zyz0922.cn.key"
echo "2. ddns-go管理界面：http://服务器IP:9876"
echo "3. 网站访问：http://zyz0922.cn:81（将自动跳转至HTTPS）"
