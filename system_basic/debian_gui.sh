#!/bin/bash

# 确保脚本以root权限运行
if [ "$(id -u)" -ne 0 ]; then
    echo "请使用root权限运行此脚本 (sudo $0)" >&2
    exit 1
fi

# 定义要卸载的软件包列表
packages=(
    "gnome-calculator"
    "gnome-calendar"
    "gnome-clocks"
    "gnome-contacts"
    "gnome-maps"
    "gnome-music"
    "gnome-sound-recorder"
    "gnome-weather"
    "goldendict-ng"
    "libreoffice*"
    "totem totem-plugins totem-common libtotem0 gir1.2-totem-1.0 libtotem-plparser18 gir1.2-totemplparser-1.0 libtotem-plparser-common"
    "gnome-snapshot"
    "evolution evolution-common evolution-data-server"
    "firefox"
    "firefox-esr"          # Firefox Extended Support Release
    "firefox-locale-en"    # Firefox语言包
)

# 循环卸载每个软件包
for pkg in "${packages[@]}"; do
    echo "正在卸载: $pkg"
    # 先检查包是否存在
    if dpkg -l $pkg &> /dev/null; then
        apt remove -y $pkg
        apt purge -y $pkg
    else
        echo "$pkg 未安装，跳过卸载"
    fi
    echo "----------------------------------------"
done

# 清理系统
echo "正在执行系统清理..."
apt autoremove -y
apt clean
apt autoclean

# 安装指定软件包
echo "正在安装必要的扩展和工具..."
apt install -y gnome-shell-extension-prefs
apt install -y chrome-gnome-shell
apt install -y gnome-shell-extension-dash-to-dock

# 安装Google Chrome
echo "开始安装Google Chrome..."

# 安装必要的依赖
echo "安装必要的依赖包..."
apt update
apt install -y wget gnupg2 apt-transport-https

# 下载并添加Google的签名密钥
echo "添加Google签名密钥..."
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /etc/apt/trusted.gpg.d/google-chrome.gpg

# 添加Google Chrome的软件源
echo "添加Google Chrome软件源..."
echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list

# 更新软件包列表并安装Google Chrome稳定版
echo "安装Google Chrome..."
apt update
apt install -y google-chrome-stable

apt install gnome-shell-extension-dashtodock -y
apt install gnome-tweaks
apt install gnome-shell-extension-manager
apt install gnome-shell-extension-appindicator

echo "所有操作已完成"
