apt install -y nginx
cp ./default /etc/nginx/sites-available/default
mkdir /ssl
chmod +x -R 777 /ssl
cp ./ssl/* /ssl/
systemctl enable nginx
systemctl start nginx
systemctl reload nginx
