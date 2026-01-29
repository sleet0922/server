tar -zxvf ./ddns-go_linux64.tar.gz
mkdir -p /usr/local/ddns-go
cp ./ddns-go /usr/local/ddns-go/

cat > /etc/systemd/system/ddns-go.service << 'EOF'
[Unit]
Description=The DDNS-GO Process Manager
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/ddns-go/ddns-go -l 0.0.0.0:9876 -c /usr/local/ddns-go/ddns_go_config.yaml
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ddns-go
systemctl start ddns-go
