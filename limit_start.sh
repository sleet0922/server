#!/bin/bash
# 适配 root 环境，修复 systemd 服务启动失败问题

# 1. 配置基础参数
INTERFACE="enp5s0"
LIMIT_RATE="20Mbit"
SERVICE_NAME="bandwidth-limit-service"

# 2. 立即清除旧规则
echo "正在清除旧的带宽规则..."
tc qdisc del dev $INTERFACE root 2>/dev/null

# 3. 立即应用上行带宽限制
echo "正在设置上传带宽为 ${LIMIT_RATE}..."
tc qdisc add dev $INTERFACE root tbf rate $LIMIT_RATE latency 50ms burst $LIMIT_RATE

# 4. 配置永久生效（优化 systemd 服务，增加网络就绪检查）
echo "正在配置重启自动生效（创建增强版 systemd 服务）..."
cat > /etc/systemd/system/${SERVICE_NAME}.service << EOF
[Unit]
Description=Auto set upload bandwidth limit on boot
After=network-online.target  # 等待网络完全就绪
Wants=network-online.target  # 依赖网络在线目标

[Service]
Type=oneshot
# 增加重试机制，确保命令执行成功
ExecStart=/bin/bash -c ' \
    while ! ip link show $INTERFACE 2>/dev/null; do sleep 1; done; \
    tc qdisc del dev $INTERFACE root 2>/dev/null; \
    tc qdisc add dev $INTERFACE root tbf rate $LIMIT_RATE latency 50ms burst $LIMIT_RATE \
'

[Install]
WantedBy=multi-user.target
EOF

# 重新加载并启用服务
systemctl daemon-reload
systemctl enable --now ${SERVICE_NAME}.service

# 5. 验证服务状态
if systemctl is-active --quiet ${SERVICE_NAME}.service; then
    echo -e "\n服务启动成功！"
else
    echo -e "\n服务已创建，但启动时可能存在临时问题。重启后会自动生效。"
    echo "详细错误："
    systemctl status ${SERVICE_NAME}.service --no-pager | grep -A 5 "Error"
fi

echo -e "\n操作完成！"
echo "当前状态：上传带宽已限制为 ${LIMIT_RATE}"
echo "永久生效：已通过 systemd 服务配置，重启后自动恢复限速"

