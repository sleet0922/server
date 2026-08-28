cat > /bin/email <<'EOF'
#!/usr/bin/env python3
import smtplib
from email.mime.text import MIMEText
from email.header import Header
import sys

if len(sys.argv) != 4:
    print("用法：email 收件人 标题 内容")
    print("示例：email sleet0528@outlook.com \"测试标题\" \"测试内容\"")
    sys.exit(1)

SMTP_SERVER = "smtp.qq.com"
SMTP_PORT = 587
SENDER = "943781228@qq.com"
PASSWORD = "aswdburijwkbbegc"

receiver = sys.argv[1]
subject = sys.argv[2]
content = sys.argv[3]

msg = MIMEText(content, 'plain', 'utf-8')
msg['From'] = SENDER
msg['To'] = receiver
msg['Subject'] = Header(subject, 'utf-8')

try:
    server = smtplib.SMTP(SMTP_SERVER, SMTP_PORT)
    server.set_debuglevel(1)
    server.starttls()
    server.login(SENDER, PASSWORD)
    server.sendmail(SENDER, [receiver], msg.as_string())
    server.quit()
    print("✅ 邮件发送成功！")
except Exception as e:
    print(f"❌ 发送失败：{e}")
    sys.exit(1)
EOF

chmod +x /bin/email
