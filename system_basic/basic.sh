#!/bin/bash
set -euo pipefail

# ===================== 前置：安装sudo并配置sleet用户权限 =====================
echo -e "\n========== 开始安装sudo并配置用户权限 ==========\n"

echo ">>> 1. 安装sudo工具"
apt update && apt install -y sudo

echo ">>> 2. 将sleet用户添加到sudo组"
# 检查sleet用户是否存在，不存在则提示（避免报错）
if id "sleet" &>/dev/null; then
    usermod -aG sudo sleet
    echo "✅ sleet用户已加入sudo组"

    # 配置sleet免密sudo（可选，提升易用性）
    echo ">>> 3. 配置sleet用户免密sudo"
    echo "sleet ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/sleet
    chmod 0440 /etc/sudoers.d/sleet
    echo "✅ sleet用户已配置免密sudo，执行sudo无需输入密码"
else
    echo "⚠️ 未找到sleet用户，跳过sudo组添加！请先创建sleet用户：useradd -m -s /bin/bash sleet"
fi

echo -e "\n========== sudo配置完成 ==========\n"

# ===================== 第一部分：永久校准Debian时间 =====================
echo -e "\n========== 开始配置系统时间永久校准 ==========\n"

# 时间配置项
TIMEZONE="Asia/Shanghai"
NTP_SERVERS="\
server ntp.aliyun.com iburst
server time1.cloud.tencent.com iburst
server pool.ntp.org iburst
"

# 检查是否为root用户（保留原有检查，避免非root执行后续操作）
if [ "$(id -u)" -ne 0 ]; then
    echo "错误：请以root用户执行此脚本（sudo ./script.sh）"
    exit 1
fi

echo ">>> 1. 备份原有时区配置"
mv /etc/localtime /etc/localtime.bak 2>/dev/null || true

echo ">>> 2. 设置时区为 $TIMEZONE"
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
echo "$TIMEZONE" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata

echo ">>> 3. 安装chrony NTP服务"
apt install -y chrony

echo ">>> 4. 配置chrony NTP服务器（替换默认配置）"
mv /etc/chrony/chrony.conf /etc/chrony/chrony.conf.bak 2>/dev/null || true
cat > /etc/chrony/chrony.conf <<EOF
$NTP_SERVERS
allow 127.0.0.1
rtcsync
makestep 1.0 3
logdir /var/log/chrony
log measurements statistics tracking
EOF

echo ">>> 5. 重启chrony服务并确保开机自启"
systemctl daemon-reload
systemctl restart chronyd
if ! systemctl is-enabled chronyd >/dev/null 2>&1; then
    CHRONY_UNIT=$(find /lib/systemd/system/ -name "chronyd.service" | head -1)
    if [ -f "$CHRONY_UNIT" ]; then
        systemctl enable "$CHRONY_UNIT"
        echo "✅ 已通过原生文件启用chronyd.service：$CHRONY_UNIT"
    else
        echo "⚠️ 未找到chronyd原生unit文件，尝试强制启用"
        systemctl enable chronyd --force
    fi
else
    echo "✅ chronyd.service已开机自启，无需重复操作"
fi

echo ">>> 6. 强制同步网络时间"
sleep 5
chronyc -a makestep || echo "⚠️ 即时同步失败，chrony会后台自动同步"

echo ">>> 7. 将系统时间同步到硬件时钟（RTC）"
hwclock --systohc --utc

echo ">>> 8. 验证时间同步状态"
echo "------------------------ 时间校准结果 ------------------------"
date
echo "------------------------ chrony同步状态 ------------------------"
chronyc tracking || echo "⚠️ 暂时无法获取同步状态，稍后可手动执行chronyc tracking检查"
echo "------------------------ 硬件时钟状态 ------------------------"
hwclock --show

echo -e "\n========== 系统时间校准配置完成 ==========\n"

# ===================== 第二部分：安装fail2ban（防SSH爆破，改用iptables） =====================
echo -e "\n========== 开始安装配置fail2ban ==========\n"

echo ">>> 1. 安装fail2ban（不安装ufw，使用默认iptables）"
apt install -y fail2ban

echo ">>> 2. 备份fail2ban默认配置并自定义规则（适配iptables）"
mv /etc/fail2ban/jail.conf /etc/fail2ban/jail.local 2>/dev/null || true
cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
# 封禁时长：1天（86400秒）
bantime  = 86400
# 检测时长：10分钟（600秒）
findtime  = 600
# 失败次数阈值：3次
maxretry = 5
# 使用iptables作为封禁手段（默认，无需额外安装）
banaction = iptables-multiport
# 忽略本地IP（避免误封）
ignoreip = 127.0.0.1/8 ::1

[sshd]
enabled = true
# SSH防护覆盖全局规则：10分钟内3次失败封禁1天
bantime  = 86400
findtime  = 600
maxretry = 5
EOF

echo ">>> 3. 重启fail2ban并设置开机自启"
systemctl restart fail2ban
systemctl enable fail2ban >/dev/null 2>&1
echo "✅ fail2ban已启用SSH防护（基于iptables），规则：10分钟内5次失败登录封禁1天"

echo ">>> 4. 验证fail2ban状态"
fail2ban-client status sshd || echo "⚠️ 暂时无法获取fail2ban状态，稍后可手动执行 fail2ban-client status sshd 检查"

echo -e "\n========== fail2ban配置完成 ==========\n"

# ===================== 第三部分：安装btop（系统资源监控） =====================
echo -e "\n========== 开始安装btop ==========\n"

echo ">>> 1. 安装btop工具"
apt install -y btop

echo ">>> 2. 验证btop安装"
if command -v btop &>/dev/null; then
    echo "✅ btop安装成功，直接执行 btop 即可启动资源监控"
else
    echo "⚠️ btop安装失败，可手动执行 apt install -y btop 重试"
fi

echo -e "\n========== btop安装完成 ==========\n"

# ===================== 第四部分：个性化配置.bashrc =====================
echo -e "\n========== 开始配置终端个性化（.bashrc） ==========\n"

# 备份原有.bashrc（避免覆盖丢失）
echo ">>> 1. 备份原有.bashrc配置"
# 优先给sleet用户配置，同时兼容root用户
for USER_HOME in /home/sleet /root; do
    if [ -d "$USER_HOME" ]; then
        mv "$USER_HOME/.bashrc" "$USER_HOME/.bashrc.bak" 2>/dev/null || true
        
        # 写入新的.bashrc配置（移除ufw相关别名，保留核心）
        echo ">>> 2. 为 $(basename $USER_HOME) 用户写入个性化.bashrc配置"
        cat > "$USER_HOME/.bashrc" << 'EOF'
# ~/.bashrc: executed by bash(1) for non-login shells.

PS1='${debian_chroot:+($debian_chroot)}\[\033[01;92m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

if [ ! -f ~/.dircolors ]; then
    dircolors -p > ~/.dircolors
fi
sed -i 's/^DIR.*01;34/DIR 01;36/' ~/.dircolors
eval "$(dircolors ~/.dircolors)"
export LS_OPTIONS='--color=auto'

# 基础别名
alias ls='ls $LS_OPTIONS'
alias ll='ls $LS_OPTIONS -l'
alias la='ls $LS_OPTIONS -la'
alias ..='cd ..'
alias ...='cd ../..'
alias ~='cd ~'
alias update='sudo apt update && sudo apt upgrade -y'
alias cls='clear'

# 防误删别名
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# 系统监控别名（仅保留fail2ban/btop相关，移除ufw）
alias h='htop'
alias b='btop'
alias df='df -h'
alias free='free -h'
alias fail2ban-status='sudo fail2ban-client status'
alias fail2ban-ssh='sudo fail2ban-client status sshd'
alias fail2ban-unban='sudo fail2ban-client set sshd unbanip'

# 历史命令时间戳
HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S "

# Less终端配色
export LESS_TERMCAP_mb=$'\E[01;92m'
export LESS_TERMCAP_md=$'\E[01;92m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;92m'
EOF
        chown $(basename $USER_HOME):$(basename $USER_HOME) "$USER_HOME/.bashrc"
    fi
done

# 应用root用户的.bashrc配置
echo ">>> 3. 应用新的.bashrc配置"
source /root/.bashrc
# 提示sleet用户重新登录生效
echo "✅ root用户.bashrc已生效，sleet用户需重新登录后终端配置生效"

echo -e "\n========== .bashrc个性化配置完成 ==========\n"

# ===================== 最终提示 =====================
echo -e "所有配置全部完成！"
