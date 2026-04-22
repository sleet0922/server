apt update && apt install samba -y && echo "[debian]
path = /
browseable = yes
writeable = yes
guest ok = no
create mask = 0777
directory mask = 0777
force user = root
" >> /etc/samba/smb.conf && echo -ne 'Zyz20050922!\nZyz20050922!\n' | smbpasswd -a root && systemctl restart smbd && hostname -I
