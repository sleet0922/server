cat > /etc/systemd/system/ddns-go.service << 'EOF'
[Unit]
Description=The DDNS-GO Process Manager
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/ddns-go/ddns-go -c /usr/local/ddns-go/ddns_go_config.yaml
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

