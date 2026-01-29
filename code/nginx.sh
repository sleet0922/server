apt install -y nginx
cp ./default /etc/nginx/sites-available/default
systemctl enable nginx
systemctl start nginx
systemctl reload nginx