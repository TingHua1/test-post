#!/bin/bash

# 星汐 VPS 监控一键安装脚本 🐷
# 支持 Ubuntu/Debian/CentOS/Alma/Rocky
# 使用方法: curl -fsSL https://raw.githubusercontent.com/TingHua1/test-post/main/install.sh | bash -s -- /your/custom/path

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
PLAIN='\033[0m'

[[ $EUID -ne 0 ]] && echo -e "${RED}错误：${PLAIN} 必须使用 root 用户运行此脚本！\n" && exit 1

REPO_URL="https://github.com/TingHua1/test-post.git"

# 解析参数
MODE=""
INSTALL_DIR="/root/vps-monitor"

while [[ $# -gt 0 ]]; do
    case "$1" in
        panel|client)
            MODE="$1"
            shift
            ;;
        *)
            INSTALL_DIR="$1"
            shift
            ;;
    esac
done

echo -e "${GREEN}🌟 星汐 VPS 监控一键安装脚本 🌟${PLAIN}"
echo ""

# 安装依赖
install_dependencies() {
    echo -e "${YELLOW}正在安装必要依赖...${PLAIN}"
    if [[ -f /usr/bin/apt ]]; then
        apt update && apt install -y python3 python3-pip git
    elif [[ -f /usr/bin/dnf ]]; then
        dnf install -y python3 python3-pip git
    elif [[ -f /usr/bin/yum ]]; then
        yum install -y python3 python3-pip git
    else
        echo -e "${RED}未能识别的系统，请手动安装 python3, pip, git${PLAIN}"
        exit 1
    fi
    
    # 安装 Python 依赖
    pip3 install flask psutil requests --break-system-packages 2>/dev/null || pip3 install flask psutil requests
}

# 克隆项目
clone_project() {
    echo -e "${YELLOW}正在克隆项目...${PLAIN}"
    
    # 如果目录已存在，更新代码
    if [[ -d "$INSTALL_DIR" ]]; then
        echo -e "${YELLOW}检测到已存在的安装目录，正在更新...${PLAIN}"
        cd "$INSTALL_DIR" && git pull
    else
        # 创建父目录（如果不存在）
        PARENT_DIR=$(dirname "$INSTALL_DIR")
        if [[ ! -d "$PARENT_DIR" ]]; then
            mkdir -p "$PARENT_DIR"
        fi
        
        # 克隆到指定目录
        git clone "$REPO_URL" "$INSTALL_DIR"
        
        # 检查克隆是否成功
        if [[ ! -d "$INSTALL_DIR" ]]; then
            echo -e "${RED}克隆失败，请检查网络连接或目录权限${PLAIN}"
            exit 1
        fi
    fi
}

# 启动面板端
start_panel() {
    echo -e "${YELLOW}正在启动面板端...${PLAIN}"
    
    # 检查目录是否存在
    if [[ ! -d "$INSTALL_DIR" ]]; then
        echo -e "${RED}错误：安装目录 ${INSTALL_DIR} 不存在！${PLAIN}"
        echo -e "${YELLOW}请先运行安装选项或检查目录路径${PLAIN}"
        exit 1
    fi
    
    cd "$INSTALL_DIR" || exit
    
    # 停止已有的进程
    pkill -f app.py 2>/dev/null
    
    # 启动面板
    nohup python3 app.py > panel.log 2>&1 &
    
    sleep 2
    
    # 获取公网IP
    PUBLIC_IP=$(curl -s ipv4.icanhazip.com 2>/dev/null || echo "localhost")
    
    echo -e "${GREEN}✅ 面板端启动成功！${PLAIN}"
    echo -e "${GREEN}🌐 访问地址: http://${PUBLIC_IP}:5000${PLAIN}"
    echo -e "${GREEN}📁 安装目录: ${INSTALL_DIR}${PLAIN}"
    echo ""
    echo -e "${YELLOW}使用以下命令查看日志:${PLAIN}"
    echo -e "  tail -f ${INSTALL_DIR}/panel.log"
}

# 启动客户端
start_client() {
    echo -e "${YELLOW}正在启动客户端...${PLAIN}"
    
    # 检查目录是否存在
    if [[ ! -d "$INSTALL_DIR" ]]; then
        echo -e "${RED}错误：安装目录 ${INSTALL_DIR} 不存在！${PLAIN}"
        echo -e "${YELLOW}请先运行安装选项或检查目录路径${PLAIN}"
        exit 1
    fi
    
    cd "$INSTALL_DIR" || exit
    
    read -p "请输入面板服务器的公网 IP: " master_ip
    read -p "请为这台 VPS 起个名字: " vps_name
    
    # 动态修改配置文件
    sed -i "s|SERVER_URL = .*|SERVER_URL = \"http://${master_ip}:5000/api/report\"|" client.py
    sed -i "s|SERVER_NAME = .*|SERVER_NAME = \"${vps_name}\"|" client.py
    
    # 停止已有的进程
    pkill -f client.py 2>/dev/null
    
    # 启动客户端
    nohup python3 client.py > client.log 2>&1 &
    
    sleep 2
    
    echo -e "${GREEN}✅ 客户端启动成功！${PLAIN}"
    echo -e "${GREEN}📡 正在上报至: http://${master_ip}:5000/api/report${PLAIN}"
    echo -e "${GREEN}🏷️  服务器名称: ${vps_name}${PLAIN}"
    echo ""
    echo -e "${YELLOW}使用以下命令查看日志:${PLAIN}"
    echo -e "  tail -f ${INSTALL_DIR}/client.log"
}

# 主菜单
show_menu() {
    echo ""
    echo -e "${GREEN}请选择要启动的模式:${PLAIN}"
    echo "  1. 安装并启动 [面板端] (监控控制台)"
    echo "  2. 安装并启动 [客户端] (被监控 VPS)"
    echo "  3. 仅安装依赖"
    echo "  0. 退出"
    echo ""
    read -p "请选择 [0-3]: " choice
    
    case $choice in
        1)
            install_dependencies
            clone_project
            start_panel
            ;;
        2)
            install_dependencies
            clone_project
            start_client
            ;;
        3)
            install_dependencies
            clone_project
            echo -e "${GREEN}✅ 安装完成！${PLAIN}"
            echo -e "安装目录: ${INSTALL_DIR}"
            ;;
        *)
            echo -e "${YELLOW}已退出${PLAIN}"
            exit 0
            ;;
    esac
}

# 根据模式执行对应功能
if [[ -n "$MODE" ]]; then
    case $MODE in
        panel)
            install_dependencies
            clone_project
            start_panel
            ;;
        client)
            install_dependencies
            clone_project
            start_client
            ;;
    esac
else
    show_menu
fi
