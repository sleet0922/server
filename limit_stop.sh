#!/bin/bash
# 适配 root 环境，与启动脚本对应

# 1. 配置基础参数（与启动脚本保持一致）
INTERFACE="enp5s0"
SERVICE_NAME="bandwidth-limit-service"

# 2. 立即解除当前限速规则
echo "正在解除当前上传带宽限制..."
tc qdisc del dev $INTERFACE root 2>/dev/null

# 3. 删除永久生效配置
echo "正在删除永久生效配置..."
systemctl stop ${SERVICE_NAME}.service 2>/dev/null
systemctl disable ${SERVICE_NAME}.service 2>/dev/null
rm -f /etc/systemd/system/${SERVICE_NAME}.service
systemctl daemon-reload

# 4. 验证结果
echo -e "\n操作完成！"
echo "当前状态：上传带宽限制已解除"
echo "永久生效：已删除 systemd 服务，重启后不再自动限速"

