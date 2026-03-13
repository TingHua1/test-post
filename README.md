# 🌸 星汐 VPS 监控系统

一个轻量级、美观的 VPS 服务器监控解决方案，支持实时监控多台服务器的 CPU、内存、磁盘、网络等资源使用情况。

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Python](https://img.shields.io/badge/python-3.8+-green.svg)
![Flask](https://img.shields.io/badge/flask-2.0+-orange.svg)

## ✨ 功能特性

- 📊 **实时监控** - 每 5 秒自动更新服务器状态
- 🎨 **美观界面** - 粉色渐变主题，玻璃态卡片设计
- 📱 **响应式布局** - 支持桌面和移动设备访问
- 🚀 **一键部署** - 单条命令完成安装和启动
- ⚡ **轻量高效** - 基于 Flask 和 psutil，资源占用低
- 🔧 **灵活配置** - 支持自定义服务器名称、上报地址、延迟测试 IP
- 📈 **丰富指标** - CPU、内存、磁盘、网络流量、延迟、运行时间

## 🚀 快速开始

### 一键安装（推荐）

#### 安装面板端（监控控制台）

```bash
curl -fsSL https://raw.githubusercontent.com/TingHua1/test-post/main/install.sh | bash
```

然后选择选项 `1` 安装并启动面板端。

#### 安装客户端（被监控 VPS）

在被监控的服务器上执行：

```bash
curl -fsSL https://raw.githubusercontent.com/TingHua1/test-post/main/install.sh | bash
```

然后选择选项 `2` 安装并启动客户端，根据提示输入面板服务器 IP 和 VPS 名称。

### 手动安装

#### 1. 克隆项目

```bash
git clone https://github.com/TingHua1/test-post.git
cd test-post
```

#### 2. 安装依赖

```bash
pip install flask psutil requests
```

#### 3. 启动面板端

```bash
python3 app.py
```

访问 `http://<服务器IP>:5000` 查看监控面板。

#### 4. 启动客户端

编辑 `client.py` 配置文件：

```python
SERVER_URL = "http://<面板服务器IP>:5000/api/report"  # 修改为你的面板服务器 IP
SERVER_NAME = "我的 VPS"  # 给你的服务器起个名字
```

然后启动客户端：

```bash
python3 client.py
```

## 📁 项目结构

```
test-post/
├── app.py              # 主应用文件（面板端）
├── server.py           # 服务器端 API
├── client.py           # 客户端监控脚本
├── start.sh            # 启动脚本
├── install.sh          # 一键安装脚本
├── templates/
│   └── index.html      # 前端模板
├── .gitignore          # Git 忽略文件
└── README.md           # 项目说明文档
```

## ⚙️ 配置说明

### 客户端配置 (client.py)

```python
# --- 配置区 ---
SERVER_URL = "http://38.76.221.101:5000/api/report"  # 面板服务器 API 地址
SERVER_ID = socket.gethostname()                      # 服务器 ID（默认主机名）
SERVER_NAME = "我的 VPS"                              # 服务器显示名称
INTERVAL = 5                                          # 上报间隔（秒）
LATENCY_TEST_IP = "202.96.128.86"                    # 延迟测试 IP（默认深圳电信）
# --------------
```

### 支持的延迟测试 IP

- **深圳电信**: `202.96.128.86`
- **北京联通**: `202.106.0.20`
- **上海电信**: `202.96.209.5`
- **广州电信**: `202.96.128.68`

## 🖥️ 系统要求

### 面板端
- Python 3.8+
- Flask
- 1GB+ 内存
- 开放 5000 端口

### 客户端
- Python 3.8+
- psutil
- requests
- 支持 Linux 系统（Ubuntu/Debian/CentOS/Alma/Rocky）

## 🌐 访问监控面板

启动面板端后，在浏览器中访问：

```
http://<面板服务器IP>:5000
```

## 📊 监控指标

| 指标 | 说明 | 单位 |
|------|------|------|
| CPU 占用 | CPU 使用率 | % |
| 内存使用 | 内存使用量和百分比 | % (MB/MB) |
| 磁盘占用 | 磁盘使用量和百分比 | % (MB/MB) |
| 网络流入 | 下载速度 | KB/s |
| 网络流出 | 上传速度 | KB/s |
| 网络总流量 | 累计流量 | GB |
| 延迟 | 到测试 IP 的延迟 | ms |
| 运行时间 | 系统运行时长 | d h m |

## 🔧 常用命令

### 查看日志

```bash
# 面板端日志
tail -f /root/vps-monitor/panel.log

# 客户端日志
tail -f /root/vps-monitor/client.log
```

### 停止服务

```bash
# 停止面板端
pkill -f app.py

# 停止客户端
pkill -f client.py

# 停止所有监控进程
pkill -f "app.py|client.py"
```

### 重启服务

```bash
# 重启面板端
pkill -f app.py
nohup python3 /root/vps-monitor/app.py > /root/vps-monitor/panel.log 2>&1 &

# 重启客户端
pkill -f client.py
nohup python3 /root/vps-monitor/client.py > /root/vps-monitor/client.log 2>&1 &
```

## 🐛 故障排除

### 客户端无法连接到面板端

1. 检查面板端是否正常运行
2. 检查防火墙是否开放 5000 端口
3. 检查 `SERVER_URL` 配置是否正确

### 数据不更新

1. 检查客户端是否正常运行：`ps aux | grep client.py`
2. 查看客户端日志：`tail -f /root/vps-monitor/client.log`
3. 检查网络连接是否正常

### 延迟测试失败

1. 检查服务器是否能 ping 通外网
2. 修改 `LATENCY_TEST_IP` 为其他可用的 IP
3. 检查服务器是否安装了 ping 命令

## 📝 更新日志

### v1.0.0 (2026-03-13)
- ✨ 初始版本发布
- 🎨 美观的粉色渐变界面
- 📊 支持 CPU、内存、磁盘、网络监控
- 🚀 一键安装脚本
- ⚡ 实时数据更新

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建你的特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交你的更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开一个 Pull Request

## 📄 开源协议

本项目基于 [MIT](LICENSE) 协议开源。

## 🙏 致谢

- [Flask](https://flask.palletsprojects.com/) - Web 框架
- [psutil](https://github.com/giampaolo/psutil) - 系统监控库
- [Bootstrap](https://getbootstrap.com/) - 前端框架

## 📧 联系方式

如有问题或建议，欢迎通过以下方式联系：

- GitHub Issues: [https://github.com/TingHua1/test-post/issues](https://github.com/TingHua1/test-post/issues)

---

Made with 💖 by 星汐
