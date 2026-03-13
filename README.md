# 🌸 星汐 VPS 监控系统

一个轻量级、美观的 VPS 服务器监控解决方案，支持实时监控多台服务器的 CPU、内存、磁盘、网络等资源使用情况。

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Python](https://img.shields.io/badge/python-3.8+-green.svg)
![Flask](https://img.shields.io/badge/flask-2.0+-orange.svg)

## ✨ 功能特性

- 📊 **实时监控** - 每 5 秒自动更新服务器状态
- 🎨 **美观界面** - 粉色渐变主题，玻璃态卡片设计
- 📱 **响应式布局** - 支持桌面和移动设备访问
- � **安全登录** - 管理员登录验证，支持修改账号密码
- �🚀 **一键部署** - 单条命令完成安装、更新和管理
- ⚡ **轻量高效** - 基于 Flask 和 psutil，资源占用低
- 🔧 **灵活配置** - 支持自定义服务器名称、上报地址、延迟测试 IP
- 📈 **丰富指标** - CPU、内存、磁盘、网络流量、延迟、运行时间

## 🚀 快速开始

### 一键安装（推荐）

#### 安装面板端（监控控制台）

```bash
curl -fsSL https://raw.githubusercontent.com/TingHua1/test-post/main/install.sh | bash
```

选择选项 `1` 安装并启动面板端。

#### 安装客户端（被监控 VPS）

在被监控的服务器上执行：

```bash
curl -fsSL https://raw.githubusercontent.com/TingHua1/test-post/main/install.sh | bash
```

选择选项 `2` 安装并启动客户端，根据提示输入面板服务器 IP 和 VPS 名称。

### 访问面板

启动面板端后，在浏览器中访问：

```
http://<面板服务器IP>:5000
```

默认登录账号：`admin`，密码：`admin123`

## ⚙️ 配置说明

### 客户端配置 (client.py)

```python
# --- 配置区 ---
SERVER_URL = "http://<面板IP>:5000/api/report"  # 面板服务器 API 地址
SERVER_NAME = "我的 VPS"                        # 服务器显示名称
INTERVAL = 5                                    # 上报间隔（秒）
LATENCY_TEST_IP = "202.96.128.86"              # 延迟测试 IP（默认深圳电信）
# --------------
```

### 延迟测试 IP 推荐

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
- psutil、requests
- 支持 Linux 系统（Ubuntu/Debian/CentOS/Alma/Rocky）

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

## 🔧 常用操作

### 管理服务

使用安装脚本进行管理：

```bash
curl -fsSL https://raw.githubusercontent.com/TingHua1/test-post/main/install.sh | bash
```

选择对应选项：
- `1` - 安装并启动面板端
- `2` - 安装并启动客户端
- `3` - 仅安装依赖
- `4` - 停止所有监控进程

### 查看日志

```bash
# 面板端日志
tail -f /root/vps-monitor/panel.log

# 客户端日志
tail -f /root/vps-monitor/client.log
```

### 重启服务

```bash
# 重启面板端
pkill -f app.py && nohup python3 /root/vps-monitor/app.py > /root/vps-monitor/panel.log 2>&1 &

# 重启客户端
pkill -f client.py && nohup python3 /root/vps-monitor/client.py > /root/vps-monitor/client.log 2>&1 &
```

## 🐛 故障排除

### 客户端无法连接
- 检查面板端是否正常运行
- 检查防火墙是否开放 5000 端口
- 检查 `SERVER_URL` 配置是否正确

### 数据不更新
- 检查客户端是否运行：`ps aux | grep client.py`
- 查看客户端日志：`tail -f /root/vps-monitor/client.log`
- 检查网络连接是否正常

### 延迟测试失败
- 检查服务器是否能 ping 通外网
- 修改 `LATENCY_TEST_IP` 为其他可用 IP
- 检查是否安装了 ping 命令

## 📝 更新日志

### v1.1.0 (2026-03-13)
- 🔐 添加登录验证功能
- 👤 支持修改账号密码
- 🛠️ 合并 start.sh 到 install.sh
- 🔄 支持项目自动更新
- 🛑 支持通过脚本停止服务

### v1.0.0 (2026-03-13)
- ✨ 初始版本发布
- 🎨 美观的粉色渐变界面
- 📊 支持 CPU、内存、磁盘、网络监控
- 🚀 一键安装脚本
- ⚡ 实时数据更新

## 📄 开源协议

本项目基于 [MIT](LICENSE) 协议开源。

## 🙏 致谢

- [Flask](https://flask.palletsprojects.com/) - Web 框架
- [psutil](https://github.com/giampaolo/psutil) - 系统监控库
- [Bootstrap](https://getbootstrap.com/) - 前端框架

---

Made with 💖 by 星汐
