import psutil
import requests
import time
import socket
import platform
import subprocess

# --- 配置区 ---
SERVER_URL = "http://38.76.221.101:5000/api/report" # 修改为你的面板服务器 IP
SERVER_ID = socket.gethostname() # 默认使用主机名
SERVER_NAME = socket.gethostname() # 默认使用主机名，可自定义
INTERVAL = 5 # 汇报间隔（秒）
LATENCY_TEST_IP = "202.96.128.86" # 延迟测试 IP，默认深圳电信
# --------------

last_net_io = psutil.net_io_counters()

def get_latency(host=LATENCY_TEST_IP):
    try:
        # Linux 下 ping 一次，超时 1 秒
        output = subprocess.check_output(["ping", "-c", "1", "-W", "1", host], 
                                         stderr=subprocess.STDOUT, universal_newlines=True)
        if "time=" in output:
            return output.split("time=")[1].split(" ")[0] + " ms"
    except:
        return "N/A"
    return "Timeout"

def get_status():
    global last_net_io
    mem = psutil.virtual_memory()
    disk = psutil.disk_usage('/')
    current_net_io = psutil.net_io_counters()
    
    # 计算网络速率 (KB/s)
    net_in_speed = (current_net_io.bytes_recv - last_net_io.bytes_recv) / INTERVAL / 1024
    net_out_speed = (current_net_io.bytes_sent - last_net_io.bytes_sent) / INTERVAL / 1024
    last_net_io = current_net_io

    # 获取运行时间
    boot_time = psutil.boot_time()
    uptime_seconds = time.time() - boot_time
    days, remainder = divmod(uptime_seconds, 86400)
    hours, remainder = divmod(remainder, 3600)
    minutes, _ = divmod(remainder, 60)
    uptime_str = f"{int(days)}d {int(hours)}h {int(minutes)}m"

    return {
        "id": SERVER_ID,
        "name": SERVER_NAME,
        "os": f"{platform.system()} {platform.release()}",
        "cpu": psutil.cpu_percent(interval=None),
        "mem_total": f"{mem.total / (1024**2):.1f}MB",
        "mem_used": f"{mem.used / (1024**2):.1f}MB",
        "mem_percent": f"{mem.percent}%",
        "mem_info": f"{mem.percent}% ({mem.used / (1024**2):.1f}MB/{mem.total / (1024**2):.1f}MB)",
        "disk_total": f"{disk.total / (1024**2):.1f}MB",
        "disk_used": f"{disk.used / (1024**2):.1f}MB",
        "disk_percent": f"{disk.percent}%",
        "disk_info": f"{disk.percent}% ({disk.used / (1024**2):.1f}MB/{disk.total / (1024**2):.1f}MB)",
        "net_in": f"{net_in_speed:.1f} KB/s",
        "net_out": f"{net_out_speed:.1f} KB/s",
        "net_total_in": f"{current_net_io.bytes_recv / (1024**3):.2f}GB",
        "net_total_out": f"{current_net_io.bytes_sent / (1024**3):.2f}GB",
        "latency": get_latency(),
        "uptime": uptime_str
    }

def run():
    print(f"🚀 星汐探针客户端 (增强版) 已启动，正在上报至 {SERVER_URL}...")
    while True:
        try:
            status = get_status()
            requests.post(SERVER_URL, json=status, timeout=5)
        except Exception as e:
            print(f"❌ 上报失败: {e}")
        time.sleep(INTERVAL)

if __name__ == "__main__":
    run()
