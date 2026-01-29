apt update
apt install -y golang
go env -w GOPROXY=https://mirrors.aliyun.com/goproxy/,direct
go install github.com/gin-gonic/gin@latest
go install gorm.io/gorm@latest
go install gorm.io/driver/mysql@latest
apt install -y nodejs
apt install -y npm
npm config set registry https://registry.npmmirror.com
npm install -g vite
