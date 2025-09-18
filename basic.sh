cp ./sshd_config /etc/ssh/sshd_config
apt install -y nginx
cp ./default /etc/nginx/sites-available/default
systemctl enable nginx
systemctl start nginx
systemctl reload nginx
systemctl restart sshd
