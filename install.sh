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

# 检查是否已安装
check_installed() {
    if [[ -d "$INSTALL_DIR" ]]; then
        return 0
    else
        return 1
    fi
}

# 检测当前运行的模式
detect_current_mode() {
    if [[ -f "$INSTALL_DIR/panel.log" ]] && ps aux | grep -v grep | grep -q "python3.*app.py"; then
        echo "panel"
    elif [[ -f "$INSTALL_DIR/client.log" ]] && ps aux | grep -v grep | grep -q "python3.*client.py"; then
        echo "client"
    else
        echo ""
    fi
}

# 安装依赖
install_dependencies() {
    echo -e "${YELLOW}正在安装必要依赖...${PLAIN}"
    if [[ -f /usr/bin/apt ]]; then
        # 先尝试修复依赖
        apt --fix-broken install -y || true
        apt update
        # 尝试安装基础包
        if ! apt install -y python3 python3-pip git; then
            echo -e "${YELLOW}apt 安装失败，尝试单独安装...${PLAIN}"
            # 单独安装 python3
            apt install -y python3 || true
            # 单独安装 python3-pip
            apt install -y python3-pip || true
            # 单独安装 git
            apt install -y git || true
        fi
    elif [[ -f /usr/bin/dnf ]]; then
        dnf install -y python3 python3-pip git
    elif [[ -f /usr/bin/yum ]]; then
        yum install -y python3 python3-pip git
    elif [[ -f /usr/bin/apk ]]; then
        # Alpine Linux
        apk update
        apk add python3 py3-pip git
    else
        echo -e "${RED}未能识别的系统，请手动安装 python3, pip, git${PLAIN}"
        exit 1
    fi
    
    # 检查是否安装成功
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}python3 安装失败，请手动安装${PLAIN}"
        exit 1
    fi
    
    if ! command -v pip3 &> /dev/null; then
        echo -e "${YELLOW}pip3 未安装，尝试使用 python3 -m pip${PLAIN}"
        PIP_CMD="python3 -m pip"
    else
        PIP_CMD="pip3"
    fi
    
    # 安装 Python 依赖
    $PIP_CMD install flask psutil requests --break-system-packages --ignore-installed 2>/dev/null || \
    $PIP_CMD install flask psutil requests --break-system-packages --ignore-installed
}

# 克隆或更新项目
clone_project() {
    echo -e "${YELLOW}正在克隆项目...${PLAIN}"
    
    # 检查 git 是否安装
    if ! command -v git &> /dev/null; then
        echo -e "${YELLOW}git 未安装，尝试使用 wget 下载...${PLAIN}"
        if command -v wget &> /dev/null; then
            # 创建安装目录
            PARENT_DIR=$(dirname "$INSTALL_DIR")
            if [[ ! -d "$PARENT_DIR" ]]; then
                mkdir -p "$PARENT_DIR"
            fi
            if [[ ! -d "$INSTALL_DIR" ]]; then
                mkdir -p "$INSTALL_DIR"
            fi
            
            # 下载项目文件
            cd "$INSTALL_DIR" || exit
            wget -O app.py https://raw.githubusercontent.com/TingHua1/test-post/main/app.py || true
            wget -O server.py https://raw.githubusercontent.com/TingHua1/test-post/main/server.py || true
            wget -O client.py https://raw.githubusercontent.com/TingHua1/test-post/main/client.py || true
            wget -O install.sh https://raw.githubusercontent.com/TingHua1/test-post/main/install.sh || true
            
            # 创建 templates 目录
            mkdir -p templates
            wget -O templates/index.html https://raw.githubusercontent.com/TingHua1/test-post/main/templates/index.html || true
            wget -O templates/login.html https://raw.githubusercontent.com/TingHua1/test-post/main/templates/login.html || true
            
            echo -e "${GREEN}✅ 项目文件下载完成！${PLAIN}"
        else
            echo -e "${RED}git 和 wget 都未安装，无法获取项目文件${PLAIN}"
            exit 1
        fi
        return
    fi
    
    # 如果目录已存在，检查是否是 git 仓库
    if [[ -d "$INSTALL_DIR" ]]; then
        if [[ -d "$INSTALL_DIR/.git" ]]; then
            echo -e "${GREEN}检测到已存在的安装，正在更新...${PLAIN}"
            cd "$INSTALL_DIR" && git pull
            echo -e "${GREEN}✅ 项目更新完成！${PLAIN}"
        else
            echo -e "${YELLOW}检测到已存在的目录但不是 git 仓库，使用 wget 更新...${PLAIN}"
            cd "$INSTALL_DIR" || exit
            wget -O app.py https://raw.githubusercontent.com/TingHua1/test-post/main/app.py || true
            wget -O server.py https://raw.githubusercontent.com/TingHua1/test-post/main/server.py || true
            wget -O client.py https://raw.githubusercontent.com/TingHua1/test-post/main/client.py || true
            wget -O install.sh https://raw.githubusercontent.com/TingHua1/test-post/main/install.sh || true
            mkdir -p templates
            wget -O templates/index.html https://raw.githubusercontent.com/TingHua1/test-post/main/templates/index.html || true
            wget -O templates/login.html https://raw.githubusercontent.com/TingHua1/test-post/main/templates/login.html || true
            echo -e "${GREEN}✅ 项目文件更新完成！${PLAIN}"
        fi
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
        echo -e "${GREEN}✅ 项目克隆完成！${PLAIN}"
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
    sleep 1
    
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
    
    # 检查是否已经配置过
    if grep -q "http://.*:5000/api/report" client.py 2>/dev/null; then
        echo -e "${GREEN}检测到已配置的客户端，直接启动...${PLAIN}"
    else
        read -p "请输入面板服务器的公网 IP: " master_ip
        read -p "请为这台 VPS 起个名字: " vps_name
        
        # 动态修改配置文件
        sed -i "s|SERVER_URL = .*|SERVER_URL = \"http://${master_ip}:5000/api/report\"|" client.py
        sed -i "s|SERVER_NAME = .*|SERVER_NAME = \"${vps_name}\"|" client.py
    fi
    
    # 停止已有的进程
    pkill -f client.py 2>/dev/null
    sleep 1
    
    # 启动客户端
    nohup python3 client.py > client.log 2>&1 &
    
    sleep 2
    
    echo -e "${GREEN}✅ 客户端启动成功！${PLAIN}"
    echo -e "${GREEN}� 安装目录: ${INSTALL_DIR}${PLAIN}"
    echo ""
    echo -e "${YELLOW}使用以下命令查看日志:${PLAIN}"
    echo -e "  tail -f ${INSTALL_DIR}/client.log"
}

# 更新并重启（重复执行时使用）
update_and_restart() {
    echo -e "${YELLOW}正在更新项目...${PLAIN}"
    
    # 安装依赖
    install_dependencies
    
    # 更新项目
    clone_project
    
    # 检测当前运行的模式
    CURRENT_MODE=$(detect_current_mode)
    
    if [[ "$CURRENT_MODE" == "panel" ]]; then
        echo -e "${GREEN}检测到面板端正在运行，正在重启...${PLAIN}"
        start_panel
    elif [[ "$CURRENT_MODE" == "client" ]]; then
        echo -e "${GREEN}检测到客户端正在运行，正在重启...${PLAIN}"
        start_client
    else
        echo -e "${YELLOW}未检测到运行中的服务，默认启动面板端...${PLAIN}"
        start_panel
    fi
}

# 停止所有服务
stop_all() {
    echo -e "${YELLOW}正在停止所有监控进程...${PLAIN}"
    pkill -f app.py 2>/dev/null
    pkill -f client.py 2>/dev/null
    echo -e "${GREEN}✅ 所有监控进程已停止${PLAIN}"
}

# 主菜单
show_menu() {
    echo ""
    echo -e "${GREEN}请选择要启动的模式:${PLAIN}"
    echo "  1. 安装并启动 [面板端] (监控控制台)"
    echo "  2. 安装并启动 [客户端] (被监控 VPS)"
    echo "  3. 仅安装依赖"
    echo "  4. 停止所有监控进程"
    echo "  0. 退出"
    echo ""
    read -p "请选择 [0-4]: " choice < /dev/tty
    
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
        4)
            stop_all
            ;;
        *)
            echo -e "${YELLOW}已退出${PLAIN}"
            exit 0
            ;;
    esac
}

# 主逻辑
if check_installed; then
    echo -e "${GREEN}检测到已安装的项目${PLAIN}"
    echo -e "${YELLOW}安装目录: ${INSTALL_DIR}${PLAIN}"
    echo ""
    
    # 如果指定了模式，执行对应操作
    if [[ -n "$MODE" ]]; then
        install_dependencies
        clone_project
        
        case $MODE in
            panel)
                start_panel
                ;;
            client)
                start_client
                ;;
        esac
    else
        # 重复执行但未指定模式，更新并重启服务
        update_and_restart
    fi
else
    # 首次安装
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
            *)
                show_menu
                ;;
        esac
    else
        show_menu
    fi
fi
