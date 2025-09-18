cp ./sshd_config /etc/ssh/sshd_config
cp ./default /etc/nginx/sites-available/default
systemctl enable nginx
systemctl start nginx
