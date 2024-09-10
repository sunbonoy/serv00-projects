#!/bin/bash

{
    echo -e "\e[0m"
	echo "#########################################################################"
	echo "安装脚本仅支持为Serv00免费主机，使用Xray内核和Hysteria2内核"
	echo "- 可选择安装Vmess+ws+tls节点配合Argo隧道，Socks5代理，Hysteria2节点"
	echo "- Argo隧道支持CF优选域名或IP使用，可自行增加"
	echo "- Xray内核支持多种协议，如果配置其它节点可自行修改或添加config.json配置文件，并启动"
	echo "- Xray配置文件的模板，请查看项目说明，地址：https://v2.hysteria.network/zh/"
	echo "#########################################################################"
    echo -e "\e[0m"
}


# 获取当前用户名
USER=$(whoami)
USER_HOME=$(readlink -f /home/$USER) # 获取标准化的用户主目录
WORK_DIR="$USER_HOME/.xray"
CLOUDF_DIR="$USER_HOME/.cloudflared"
HY_WORKDIR="$USER_HOME/.hysteria"
FILE_DIR="$USER_HOME/output"

# 创建必要的目录，如果不存在
[ ! -d "$WORK_DIR" ] && mkdir -p "$WORK_DIR"
[ ! -d "$CLOUDF_DIR" ] && mkdir -p "$CLOUDF_DIR"
[ ! -d "$HY_WORKDIR" ] && mkdir -p "$HY_WORKDIR"
[ ! -d "$FILE_DIR" ] && mkdir -p "$FILE_DIR"

# 设置Argo端口
set_server_port() {
  read -p "请输入argo端口 (Serv00面板上开放的TCP端口）: " input_port
  export SERVER_PORT="${input_port}"
}

# 设置s5端口
set_s5_port() {
  read -p "请输入socks5端口 (Serv00面板上开放的TCP端口）: " input_s5
  export S5_PORT="${input_s5}"
}

# 设置hy2端口
set_hy2_port() {
  read -p "请输入hysteria端口 (Serv00面板上开放的UDP端口）: " input_hy
  export HY_PORT="${input_hy}"
}

# 生成hy2密码
generate_hy2_password() {
  export HY_PASSWORD=${password:-$(openssl rand -base64 32 | tr -d '=+/' | cut -c1-12)}
}

# 设置socks用户名
set_s5_user() {
  read -p "请输入Socks5代理的用户名(留空则随机生成): " s5_user
  export S5_USER=${s5_user:-$(openssl rand -base64 32 | tr -d '=+/' | cut -c1-8)}
}

# 设置socks密码
set_s5_password() {
  read -p "请输入Socks5代理的密码(留空则随机生成): " s5_password
  export S5_PASSWORD=${s5_password:-$(openssl rand -base64 32 | tr -d '=+/' | cut -c1-8)}
}

# 使用xray并生成随机uuid
generate_uuid() {
  UUID=$("$WORK_DIR/x5" uuid)

}

# 设置隧道Token
set_argo_token() {
  read -p "请输入你的隧道Token (在Cloud flare上新建隧道后获取）: " token
  export ARGO_TOKEN="${token}"
 }

# 设置Argo隧道域名
set_domains() {
  read -p "请输入你的Argo隧道域名 (在Cloud flare上完成隧道设置后的域名）: " domains
  export ARGO_DOMAINS="${domains}"
 }

# 生成证书函数
generate_cert() {
  openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) -keyout "$HY_WORKDIR/server.key" -out "$HY_WORKDIR/server.crt" -subj "/CN=bing.com" -days 36500
}

# 获取IP地址, ipv6优先
get_ip() {
  ip=$(curl --max-time 3 ifconfig.co/)
  if [[ -n "$ip" ]]; then
    if [[ "$ip" =~ : ]]; then
    HOST_IP="[$ip]"
	else
	HOST_IP="$ip"
	fi
  else   
    echo -e "\e[1;35m无法获取IPv4或IPv6地址\033[0m"
    exit 1
  fi
  echo -e "\e[1;32m本机IP: $HOST_IP\033[0m"
}

# 下载安装Xray
download_xray() {
  ARCH=$(uname -m)

  cd "$WORK_DIR/"
  # 根据不同架构下载对应的文件
  case "$ARCH" in
    "arm" | "arm64" | "aarch64")
      URL="https://github.com/XTLS/Xray-core/releases/download/v1.8.23/Xray-freebsd-arm64-v8a.zip"
      ;;
    "amd64" | "x86_64" | "x86")
      URL="https://github.com/XTLS/Xray-core/releases/download/v1.8.23/Xray-freebsd-64.zip"
      ;;
    *)
      echo "不支持的架构: $ARCH"
      exit 1
      ;;
  esac  
  
  # 使用 curl 下载文件
  echo "正在下载 Xray..."
  if curl -sL --connect-timeout 10 --max-time 60 "$URL" -o xray.zip; then
    echo -e "\e[1;32m下载完成\e[0m"
  else
    echo -e "\e[1;32m下载失败，请检查网络连接或URL地址\e[0m"
    exit 1
  fi

  # 检查下载的文件是否存在并解压缩
  if [[ -f "xray.zip" ]]; then
    unzip xray.zip && rm xray.zip
  else
    echo -e "\e[1;32m解压文件失败，请检查文件是否存在或损坏\e[0m"
    exit 1
  fi
  
  # 重命名并设置权限
  if [[ -f "xray" ]]; then
    mv xray x5
    chmod +x x5
  else
    echo -e "\e[1;32m未找到xray文件, 请检查文件名正确与否？\e[0m"
    exit 1
fi
  echo -e "\e[1;32mXray安装已完成\e[0m"
}

# 生成vless+ws的配置文件
generate_config() {
  cat << EOF > "$WORK_DIR/config.json"
{
    "log": {
        "loglevel": "warning"
    },
    "routing": {
        "domainStrategy": "IPIfNonMatch",
        "rules": [
            {
                "type": "field",
                "ip": [
                    "geoip:cn",
                    "geoip:private"
                ],
                "outboundTag": "block"
            }
        ]
    },
    "inbounds": [
        {
            "listen": "127.0.0.1",
            "port": $SERVER_PORT,
            "protocol": "vmess",
            "settings": {
                "clients": [
                  {
                    "id": "$UUID",
                    "alterId": 0
                  }
                ],
                "disableInsecureEncryption": false
              },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                  "acceptProxyProtocol": false,
                  "path": "/?ed=2048",
                  "headers": {}
                }
              },
              "sniffing":{
                "enabled": false,
                "destOverride": [
                  "http",
                  "tls"
                ]
              }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "tag": "direct"
        },
        {
            "protocol": "blackhole",
            "tag": "block"
        }
    ]
}
EOF
}

# 生成socks5的配置文件
generate_s5_config() {
  cat << EOF > "$WORK_DIR/config-s5.json"
{
    "log": {
        "loglevel": "warning"
    },
    "inbounds": [
        {
            "listen": "0.0.0.0",
            "port": $S5_PORT,
            "protocol": "socks",
            "settings": {
                "auth": "password",
                "userLevel": 0,
                "accounts": [
                    {
                        "user": "$S5_USER",
                        "pass": "$S5_PASSWORD"
                    }
                ],
                "udp": false,
                "ip": "127.0.0.1"
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "tag": "direct"
        },
        {
            "protocol": "blackhole",
            "tag": "block"
        }
    ]
}

EOF
}

# 检查xray
check_xray() {
  if [[ -e "$WORK_DIR/x5" ]]; then
    echo -e "\e[1;32mxray已安装，继续进行配置\e[0m"
  else
    echo -e "\e[1;32mxray没有安装，请先安装xray\e[0m"
	exit 1
  fi
}

# 运行xray配置文件
run_xray() {
    local run_s5=$1
	if [ "$run_s5" == "true" ]; then
	  nohup "$WORK_DIR/x5" -c "$WORK_DIR/config-s5.json" >/dev/null 2>&1 &
      sleep 1
	  echo -e "\e[1;32mSocks5代理启动\e[0m"
	else
	  nohup "$WORK_DIR/x5" -c "$WORK_DIR/config.json" >/dev/null 2>&1 &
      sleep 1
      echo -e "\e[1;32mVless+ws节点启动\e[0m"
	fi
}

# 输出argo客户端配置
argo_output() {
  # 定义输出文件的路径
  OUTPUT_FILE="$FILE_DIR/client.txt"
  VMESS="{ \"v\": \"2\", \"ps\": \"serv00-VM-argo\", \"add\": \"www.visa.com\", \"port\": \"443\", \"id\": \"$UUID\", \"aid\": \"0\", \"scy\": \"none\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"$ARGO_DOMAINS\", \"path\": \"/?ed=2048\", \"tls\": \"tls\", \"sni\": \"$ARGO_DOMAINS\", \"alpn\": \"\" }"
  # 输出并写入文件
  echo -e "\e[1;32m将输出客户端节点配置信息，配置文件路径：$FILE_DIR/client.txt\033[0m"
  cat << EOF | tee -a "$OUTPUT_FILE"

客户端V2ray和Nekobox

Vmess+ws+Argo隧道：
vmess://$(echo -n "$VMESS" | base64 -w0)

EOF
}

# 输出socks5代理配置
s5_output() {
  # 定义输出文件的路径
  OUTPUT_FILE="$FILE_DIR/client.txt"

  # 输出并写入文件
  echo -e "\e[1;32m将输出客户端节点配置信息，配置文件路径：$FILE_DIR/client.txt\033[0m"
  cat << EOF | tee -a "$OUTPUT_FILE"

Socks5代理
IP地址:$HOST_IP
端口:$S5_PORT
用户名:$S5_USER
密码:$S5_PASSWORD

EOF
}

# 下载安装Cloudflared
download_cloudflared() {
  cd "$CLOUDF_DIR/"
  URL="https://github.com/sunbonoy/serv00-projects/raw/main/cloudflared/cloudflared-freebsd-2024.8.3.7z"
  
  # 使用 curl 下载文件
  echo "正在下载 Cloudflared..."
  if curl -sL --connect-timeout 10 --max-time 60 "$URL" -o cloudflared.7z; then
    echo -e "\e[1;32m下载完成\e[0m"
  else
    echo -e "\e[1;32m下载失败，请检查网络连接或URL地址\e[0m"
    exit 1
  fi

  # 检查下载的文件是否存在并解压缩
  if [[ -f "cloudflared.7z" ]]; then
    7z x cloudflared.7z && rm cloudflared.7z
  else
    echo -e "\e[1;32m解压文件失败，请检查文件是否存在或损坏\e[0m"
    exit 1
  fi
  
  # 重命名并设置权限
  if [[ -f "cloudflared-freebsd-2024.8.3" ]]; then
    mv cloudflared-freebsd-2024.8.3 argo
    chmod +x argo
  else
    echo -e "\e[1;32m未找到cloudflared文件, 请检查文件名正确与否？\e[0m"
    exit 1
fi
  echo -e "\e[1;32mCloudflared安装已完成\e[0m"
}

# 运行Argo隧道
run_argo() {
  if [[ -e "$CLOUDF_DIR/argo" ]]; then
    nohup "$CLOUDF_DIR/argo" tunnel --edge-ip-version auto --protocol http2 --heartbeat-interval 10s run --token "$ARGO_TOKEN" >/dev/null 2>&1 &
    sleep 1
    echo -e "\e[1;32mArgo隧道启动...\e[0m"
	echo -e "\e[1;32m请完成在CF上的域名设置...\e[0m"
  fi
  }

# 下载hysteria文件
download_hysteria() {
  ARCH=$(uname -m)
  cd "$HY_WORKDIR/"
  # 根据不同架构下载对应的文件
  case "$ARCH" in
    "arm" | "arm64" | "aarch64")
      URL="https://download.hysteria.network/app/latest/hysteria-freebsd-arm64"
      ;;
    "amd64" | "x86_64" | "x86")
      URL="https://download.hysteria.network/app/latest/hysteria-freebsd-amd64"
      ;;
    *)
      echo "不支持的架构: $ARCH"
      exit 1
      ;;
  esac  
  
  # 使用 curl 下载文件
  echo "正在下载 Hysteria2..."
  if curl -sL --connect-timeout 10 --max-time 60 "$URL" -o web; then
    echo -e "\e[1;32m下载完成\e[0m"
  else
    echo -e "\e[1;32m下载失败，请检查网络连接或URL地址\e[0m"
    exit 1
  fi

  # 设置权限
  if [[ -f "web" ]]; then
    chmod +x web
  else
    echo -e "\e[1;32m未找到Hysteria执行文件, 请检查文件名正确与否？\e[0m"
    exit 1
fi
  echo -e "\e[1;32mHysteria2安装已完成\e[0m"
  
}

# 生成Hysteria配置文件
generate_hy2_config() {
  cat << EOF > "$HY_WORKDIR/config.yaml"
listen: :$HY_PORT

tls:
  cert: $HY_WORKDIR/server.crt
  key: $HY_WORKDIR/server.key

auth:
  type: password
  password: "$HY_PASSWORD"

fastOpen: true

masquerade:
  type: proxy
  proxy:
    url: https://bing.com
    rewriteHost: true

transport:
  udp:
    hopInterval: 30s
EOF
}

# 运行Hysteria2
run_hy2() {
  if [[ -e "$HY_WORKDIR/web" ]]; then
    nohup "$HY_WORKDIR/web" server "$HY_WORKDIR/config.yaml" >/dev/null 2>&1 &
    sleep 1
    echo -e "\e[1;32mHysteria2正在运行\e[0m"
  fi
}

# 输出Hysteria客户端配置
hy2_output() {
  # 定义输出文件的路径
  OUTPUT_FILE="$FILE_DIR/client.txt"

  # 输出并写入文件
  echo -e "\e[1;32m将输出客户端节点配置信息，配置文件路径：$FILE_DIR/client.txt\033[0m"
  cat << EOF | tee -a "$OUTPUT_FILE"

客户端V2rayN和Nekobox

hysteria2://$HY_PASSWORD@$HOST_IP:$HY_PORT/?sni=www.bing.com&alpn=h3&insecure=1#Serv00-hy2

EOF
}

# 检查并显示文件内容
print_config() {
  if [ -f "$FILE_DIR/client.txt" ]; then
    echo -e "\e[1;32m所有节点配置信息如下： \e[0m"
	cat "$FILE_DIR/client.txt"
  else
    echo -e "\e[1;32m没有配置文件，请检查路径和文件\e[0m"
	exit 1
  fi
}

# 安装Xray
install_xray() {
  download_xray
}

# 安装Argo
install_argo() {
  check_xray
  download_cloudflared
  set_server_port
  set_argo_token
  run_argo
  set_domains
  generate_uuid
  generate_config
  run_xray false
  argo_output
}

# 安装socks5代理
install_s5() {
  check_xray
  set_s5_port
  set_s5_user
  set_s5_password
  get_ip
  generate_s5_config
  run_xray true
  s5_output
}

# 安装 Hysteria
install_hy2() {
  generate_hy2_password
  set_hy2_port
  get_ip
  download_hysteria
  generate_cert
  generate_hy2_config
  run_hy2
  hy2_output
}

# 主程序
while true; do
echo -e "\e[1;32m 1. 安装Xray(使用Argo和Socks5代理必须安装)\033[0m"
echo -e "\e[1;32m 2. 安装Argo隧道\033[0m"
echo -e "\e[1;32m 3. 安装Socks5代理\033[0m"
echo -e "\e[1;32m 4. 安装Hysteria2\033[0m"
echo -e "\e[1;32m 5. 输出所有节点配置信息\033[0m"
echo -e "\e[1;32m 6. 不安装，退出\033[0m"
read -rp "请输入选项 [1-6]: " menuInput
case $menuInput in
    1) 
      install_xray
      ;;
    2) 
      install_argo 
      ;;
    3) 
      install_s5
	  ;;
	4) 
      install_hy2
	  ;;
    5) 
      print_config	  
      ;;
    6) 
      echo "退出脚本。"
      exit 0
      ;;
    *) 
      echo "无效选项，请输入 1 到 5 之间的数字。"
      ;;
  esac

  # 回到菜单选择
  echo
done
