#!/bin/bash
# Gmail 邮件服务一键部署脚本（root用户专用）
# 功能：安装msmtp → 配置.msmtprc → 创建全局email发送脚本

set -e  # 遇到错误立即退出

# ====================== 配置项（请先修改这里为你的实际信息）======================
GMAIL_ACCOUNT="sleet0528@gmail.com"       # 你的Gmail邮箱
GMAIL_APP_PASSWORD="lwlq hryu pbib jufg"  # Gmail应用专用密码
SENDER_NICKNAME="LiLi"                    # 发件人显示昵称
DEFAULT_EMAIL_CONTENT="无正文内容"        # 邮件默认正文
# ================================================================================

echo -e "\n=============== 开始部署Gmail邮件发送服务 ==============="

# 1. 更新系统并安装msmtp
echo -e "\n【1/4】安装msmtp邮件客户端..."
apt update && apt install -y msmtp nano

# 2. 配置.msmtprc文件
echo -e "\n【2/4】配置msmtp（/root/.msmtprc）..."
cat > /root/.msmtprc << EOF
defaults
auth           on
tls            on
tls_starttls   on
tls_certcheck  off
logfile        ~/.msmtp.log

account        gmail
host           smtp.gmail.com
port           587
from           ${GMAIL_ACCOUNT}
user           ${GMAIL_ACCOUNT}
password       ${GMAIL_APP_PASSWORD}

account default : gmail
EOF

# 设置.msmtprc权限（msmtp要求600权限）
chmod 600 /root/.msmtprc

# 3. 创建全局email发送脚本
echo -e "\n【3/4】创建全局email发送脚本..."
cat > /usr/local/bin/email << EOF
#!/bin/bash
# Gmail 邮件发送脚本（全局可用：email 收件人 标题 [正文]）
# 使用示例：
#   email 943781228@qq.com "测试标题" "这是测试正文"
#   email 943781228@qq.com "无正文标题"

# 固定配置
SENDER_EMAIL="${GMAIL_ACCOUNT}"
SENDER_NAME="${SENDER_NICKNAME}"
DEFAULT_CONTENT="${DEFAULT_EMAIL_CONTENT}"

# 参数检查
if [ \$# -lt 2 ]; then
    echo "❌ 使用错误！正确格式："
    echo "   email 收件人邮箱 \"邮件标题\" [邮件正文]"
    echo "示例1：email 943781228@qq.com \"测试标题\" \"这是测试正文\""
    echo "示例2：email 943781228@qq.com \"无正文标题\""
    exit 1
fi

# 提取参数
TO_EMAIL="\$1"
SUBJECT="\$2"
CONTENT="\${3:-\${DEFAULT_CONTENT}}"

# 发送邮件
cat << MAIL_CONTENT | msmtp "\${TO_EMAIL}"
From: \${SENDER_NAME} <\${SENDER_EMAIL}>
To: \${TO_EMAIL}
Subject: \${SUBJECT}
Content-Type: text/plain; charset=UTF-8

\${CONTENT}
MAIL_CONTENT

# 结果反馈
if [ \$? -eq 0 ]; then
    echo "✅ 邮件发送成功！"
    echo "📤 收件人：\${TO_EMAIL}"
    echo "📌 标题：\${SUBJECT}"
    echo "📝 正文：\${CONTENT}"
else
    echo "❌ 邮件发送失败！请检查："
    echo "   1. .msmtprc 配置是否正确"
    echo "   2. Gmail应用密码是否有效"
    echo "   3. 网络是否正常"
    exit 1
fi
EOF

# 赋予脚本执行权限
chmod +x /usr/local/bin/email

# 4. 验证部署
echo -e "\n【4/4】部署完成！验证使用方法："
echo -e "\n📌 测试发送命令（替换收件人）："
echo "   email 943781228@qq.com \"部署成功测试\" \"邮件服务已一键部署完成！\""
echo -e "\n📌 查看脚本帮助："
echo "   email（直接执行会显示用法提示）"

echo -e "\n=============== 部署完成 ===============\n"
