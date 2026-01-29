#!/bin/bash
set -euo pipefail

# ===================== 配置腾讯+阿里云DNS =====================
echo -e "\n========== 开始配置腾讯+阿里云DNS ==========\n"

# 检查是否为root用户
if [ "$(id -u)" -ne 0 ]; then
    echo "错误：请以root用户执行此脚本（sudo ./dns-config.sh）"
    exit 1
fi

# 定义DNS配置（腾讯+阿里，IPv4优先，IPv6可选）
IPV4_DNS=(
    "223.5.5.5"   # 阿里云主DNS
    "223.6.6.6"   # 阿里云备DNS
    "119.29.29.29" # 腾讯云主DNS
    "182.254.116.116" # 腾讯云备DNS
)
IPV6_DNS=(
    "2400:3200::1" # 阿里云IPv6主DNS
    "2400:3200::2" # 阿里云IPv6备DNS
    "240c::6666"   # 腾讯云IPv6 DNS
)

# 步骤1：备份原有配置
echo ">>> 1. 备份原有配置文件"
# 备份dhcpcd（若存在）
if [ -f "/etc/dhcpcd.conf" ]; then
    cp /etc/dhcpcd.conf /etc/dhcpcd.conf.bak.$(date +%F)
    echo "✅ 已备份dhcpcd.conf"
else
    echo "⚠️ 未找到dhcpcd.conf，跳过备份"
fi
# 备份resolv.conf
cp /etc/resolv.conf /etc/resolv.conf.bak.$(date +%F) 2>/dev/null || true
echo "✅ 已备份resolv.conf（后缀为当日日期）"

# 步骤2：配置dhcpcd（仅当文件存在时）
if [ -f "/etc/dhcpcd.conf" ]; then
    echo -e "\n>>> 2. 配置dhcpcd，禁用DHCP自动DNS获取"
    # 先删除已存在的重复配置
    sed -i '/nohook resolv.conf/d' /etc/dhcpcd.conf
    sed -i '/static domain_name_servers/d' /etc/dhcpcd.conf
    sed -i '/static domain_name_servers_ipv6/d' /etc/dhcpcd.conf

    # 添加自定义DNS配置
    cat >> /etc/dhcpcd.conf << EOF

# 手动配置DNS（腾讯+阿里云）- 禁用DHCP自动覆盖
nohook resolv.conf
static domain_name_servers=${IPV4_DNS[*]}
static domain_name_servers_ipv6=${IPV6_DNS[*]}
EOF
    echo "✅ dhcpcd配置完成"
else
    echo -e "\n⚠️ 未找到dhcpcd.conf，跳过dhcpcd配置（系统未使用dhcpcd管理网络）"
fi

# 步骤3：更新resolv.conf文件（核心，确保DNS生效）
echo -e "\n>>> 3. 写入自定义DNS到resolv.conf"
# 解锁resolv.conf（若之前锁定）
chattr -i /etc/resolv.conf 2>/dev/null || true

# 新建resolv.conf（仅保留腾讯+阿里DNS）
cat > /etc/resolv.conf << EOF
# 腾讯+阿里云DNS（手动配置，禁止自动覆盖）
# IPv4 DNS
$(for dns in "${IPV4_DNS[@]}"; do echo "nameserver $dns"; done)
# IPv6 DNS（可选）
$(for dns in "${IPV6_DNS[@]}"; do echo "nameserver $dns"; done)
EOF

# 锁定resolv.conf，防止被任何程序覆盖
chattr +i /etc/resolv.conf
echo "✅ resolv.conf已写入腾讯+阿里DNS，并锁定文件防止修改"

# 步骤4：重启网络服务（适配不同网络管理工具）
echo -e "\n>>> 4. 重启网络服务使配置生效"
# 尝试重启dhcpcd（仅当服务存在时）
if systemctl list-unit-files | grep -q "dhcpcd.service"; then
    systemctl restart dhcpcd 2>/dev/null || echo "⚠️ dhcpcd服务重启失败（可能未安装）"
# 尝试重启systemd-networkd（Debian服务器默认）
elif systemctl list-unit-files | grep -q "systemd-networkd.service"; then
    systemctl restart systemd-networkd
    echo "✅ 已重启systemd-networkd服务"
# 尝试重启NetworkManager（桌面版）
elif systemctl list-unit-files | grep -q "NetworkManager.service"; then
    systemctl restart NetworkManager
    echo "✅ 已重启NetworkManager服务"
else
    echo "⚠️ 未识别到网络管理服务，建议手动重启网络或服务器"
fi

# 步骤5：验证配置结果
echo -e "\n>>> 5. 验证DNS配置"
echo -e "\n===== 当前resolv.conf配置 ====="
cat /etc/resolv.conf

echo -e "\n===== 测试DNS解析（阿里云） ====="
dig aliyun.com | grep -E ';; SERVER:|ANSWER SECTION' || echo "⚠️ 解析测试失败（可能网络问题）"

echo -e "\n===== 测试DNS解析（腾讯云） ====="
dig qq.com | grep -E ';; SERVER:|ANSWER SECTION' || echo "⚠️ 解析测试失败（可能网络问题）"

echo -e "\n===== DNS延迟测试 ====="
for dns in "${IPV4_DNS[@]}"; do
    echo -n "$dns 延迟："
    ping -c 1 -W 1 $dns | grep 'time=' | awk '{print $7}' || echo "超时"
done

# ===================== 完成提示 =====================
echo -e "\n🎉 DNS配置全部完成！"
echo "1. 已将DNS永久替换为腾讯+阿里云（IPv4+IPv6）"
echo "2. resolv.conf已锁定，防止被自动覆盖"
echo "3. 若需修改DNS，先执行：sudo chattr -i /etc/resolv.conf"
echo "4. 若需恢复原有配置，执行："
echo "   sudo chattr -i /etc/resolv.conf && sudo cp /etc/resolv.conf.bak.$(date +%F) /etc/resolv.conf"
if [ -f "/etc/dhcpcd.conf.bak.$(date +%F)" ]; then
    echo "   sudo cp /etc/dhcpcd.conf.bak.$(date +%F) /etc/dhcpcd.conf"
fi