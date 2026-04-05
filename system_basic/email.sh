cat > /bin/email <<'EOF'
#!/bin/bash
if [ $# -ne 3 ]; then
echo "用法：email 收件人 标题 内容"
echo "示例：email sleet0528@outlook.com \"测试标题\" \"测试内容\""
exit 1
fi

sendEmail -f 943781228@qq.com -t "$1" -u "$2" -m "$3" \
-s smtp.qq.com:587 \
-o tls=auto \
-xu 943781228@qq.com \
-xp "aswdburijwkbbegc" \
-o message-charset=utf-8
EOF

chmod +x /bin/email
echo "✅ 修复完成！现在可以正常发送中文邮件了"
