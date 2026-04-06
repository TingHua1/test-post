import psutil
import requests
import time
import socket
import platform
import subprocess

# --- 配置区 ---
SERVER_URL = "http://<面板IP>:5000/api/report"
SERVER_ID = socket.gethostname()
SERVER_NAME = socket.gethostname()
INTERVAL = 5
LATENCY_TEST_IP = "202.96.128.86"
API_KEY = ""
# --------------

last_net_io = psutil.net_io_counters()

def get_latency(host=LATENCY_TEST_IP):
    try:
        output = subprocess.check_output(["ping", "-c", "1", "-W", "1", host], 
                                         stderr=subprocess.STDOUT, universal_newlines=True)
        if "time=" in output:
            return output.split("time=")[1].split(" ")[0] + " ms"
        return "Timeout"
    except:
        return "N/A"

def get_status():
    global last_net_io
    mem = psutil.virtual_memory()
    disk = psutil.disk_usage('/')
    current_net_io = psutil.net_io_counters()
    
    net_in_speed = (current_net_io.bytes_recv - last_net_io.bytes_recv) / INTERVAL / 1024
    net_out_speed = (current_net_io.bytes_sent - last_net_io.bytes_sent) / INTERVAL / 1024
    last_net_io = current_net_io

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
    retry_count = 0
    max_retries = 3
    
    while True:
        try:
            status = get_status()
            headers = {}
            if API_KEY:
                headers['Authorization'] = f'Bearer {API_KEY}'
            
            response = None
            for attempt in range(max_retries):
                try:
                    response = requests.post(SERVER_URL, json=status, timeout=5, headers=headers)
                    if response.status_code == 200:
                        retry_count = 0
                        break
                except Exception as e:
                    if attempt < max_retries - 1:
                        time.sleep(1)
                    continue
            
            if response and response.status_code != 200:
                print(f"❌ 上报失败 (HTTP {response.status_code}): {response.text}")
                retry_count += 1
                if retry_count > 10:
                    print(f"⚠️  连续失败次数过多，请检查配置")
                    retry_count = 10
            
        except Exception as e:
            print(f"❌ 上报失败: {e}")
            retry_count += 1
        
        time.sleep(INTERVAL)

if __name__ == "__main__":
    run()
