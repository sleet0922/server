mkdir -p /ssl
cd /ssl

# 生成私钥（使用更强的2048位）
openssl genrsa -out v.cn.key 2048

# 创建证书配置文件（不包含IP）
cat > v.cn.cnf << 'EOF'
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
x509_extensions = v3_req

[dn]
C = CN
ST = Beijing
L = Beijing
O = MyCompany
OU = IT
CN = v.cn

[v3_req]
subjectAltName = @alt_names

[alt_names]
DNS.1 = v.cn
DNS.2 = www.v.cn
EOF

# 生成自签名证书（有效期10年）
openssl req -new -x509 -days 3650 -key v.cn.key -out v.cn.crt -config v.cn.cnf

# 生成PFX格式（用于Windows导入）
openssl pkcs12 -export -out v.cn.pfx -inkey v.cn.key -in v.cn.crt -password pass:123456

# 设置权限
chmod 644 /ssl/*
