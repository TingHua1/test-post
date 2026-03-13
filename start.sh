#!/bin/bash

# 星汐的 VPS 监控一键脚本 🐷
# 支持 Ubuntu/Debian/CentOS/Alma/Rocky

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
PLAIN='\033[0m'

[[ $EUID -ne 0 ]] && echo -e "${RED}错误：${PLAIN} 必须使用 root 用户运行此脚本！\n" && exit 1

install_dependencies() {
    echo -e "${YELLOW}正在安装必要依赖...${PLAIN}"
    if [[ -f /usr/bin/apt ]]; then
        apt update && apt install -y python3-flask python3-psutil python3-requests python3-pip
    elif [[ -f /usr/bin/dnf ]]; then
        dnf install -y python3-flask python3-psutil python3-requests
    elif [[ -f /usr/bin/yum ]]; then
        yum install -y python3-flask python3-psutil python3-requests
    else
        echo -e "${RED}未能识别的系统，请手动安装 python3, flask, psutil, requests${PLAIN}"
    fi
    # 额外兼容 PEP 668 环境
    pip3 install flask psutil requests --break-system-packages 2>/dev/null
}

start_panel() {
    cd /root/vps-monitor || exit
    pkill -f app.py
    nohup python3 app.py > panel.log 2>&1 &
    echo -e "${GREEN}面板端启动成功！${PLAIN}"
    echo -e "访问地址: http://$(curl -s ipv4.icanhazip.com):5000"
}

start_client() {
    cd /root/vps-monitor || exit
    read -p "请输入面板服务器的公网 IP: " master_ip
    read -p "请为这台 VPS 起个名字: " vps_name
    
    # 动态修改配置文件
    sed -i "s/SERVER_URL = .*/SERVER_URL = \"http:\/\/${master_ip}:5000\/api\/report\"/" client.py
    sed -i "s/SERVER_NAME = .*/SERVER_NAME = \"${vps_name}\"/" client.py
    
    pkill -f client.py
    nohup python3 client.py > client.log 2>&1 &
    echo -e "${GREEN}客户端启动成功！正在上报至 ${master_ip}...${PLAIN}"
}

echo -e "${GREEN}🌟 星汐 VPS 监控一键管理脚本 🌟${PLAIN}"
echo -e "  1. 安装环境并启动 [面板端] (控制台)"
echo -e "  2. 安装环境并启动 [客户端] (受监控 VPS)"
echo -e "  3. 停止所有监控进程"
echo -e "  0. 退出脚本"
read -p "请选择 [0-3]: " choice

case $choice in
    1)
        install_dependencies
        start_panel
        ;;
    2)
        install_dependencies
        start_client
        ;;
    3)
        pkill -f app.py
        pkill -f client.py
        echo -e "${YELLOW}所有监控进程已停止。${PLAIN}"
        ;;
    *)
        exit 0
        ;;
esac
