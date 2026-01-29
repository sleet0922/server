apt install ./mihomo.deb
systemctl start mihomo
cp -f ./config.yaml /etc/mihomo/config.yaml
alias vpn='systemctl start mihomo && export http_proxy=http://127.0.0.1:7890 && export https_proxy=http://127.0.0.1:7890 && export ALL_PROXY=socks5://127.0.0.1:7891'
echo "alias vpn='systemctl start mihomo && export http_proxy=http://127.0.0.1:7890 && export https_proxy=http://127.0.0.1:7890 && export ALL_PROXY=socks5://127.0.0.1:7891'" >> /root/.bashrc
source /root/.bashrc