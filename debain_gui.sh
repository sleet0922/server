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
)

# 循环卸载每个软件包
for pkg in "${packages[@]}"; do
    echo "正在卸载: $pkg"
    apt remove -y $pkg
    apt purge -y $pkg
    echo "----------------------------------------"
done

# 清理系统
echo "正在执行系统清理..."
apt autoremove -y
apt clean
apt autoclean

echo "所有操作已完成"
