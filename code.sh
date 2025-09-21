apt update
apt install -y golang
go env -w GOPROXY=https://mirrors.aliyun.com/goproxy/,direct
apt install -y nodejs
apt install -y npm
npm config set registry https://registry.npmmirror.com
npm install -g vite
