from flask import Flask, render_template, request, jsonify
import time
from threading import Lock

app = Flask(__name__)

# 存储服务器数据，格式: { 'hostname': { 'ip': '...', 'cpu': '...', 'mem': '...', 'last_seen': ... } }
servers_data = {}
data_lock = Lock()

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/report', methods=['POST'])
def report():
    data = request.json
    hostname = data.get('hostname')
    if hostname:
        with data_lock:
            data['last_seen'] = time.time()
            servers_data[hostname] = data
        return jsonify({"status": "ok"}), 200
    return jsonify({"status": "error"}), 400

@app.route('/api/data')
def get_data():
    with data_lock:
        # 清理超过 30 秒没报到的服务器（视为离线）
        now = time.time()
        for h in list(servers_data.keys()):
            if now - servers_data[h]['last_seen'] > 30:
                servers_data[h]['status'] = 'offline'
            else:
                servers_data[h]['status'] = 'online'
        return jsonify(list(servers_data.values()))

if __name__ == '__main__':
    # 默认运行在 5000 端口
    app.run(host='0.0.0.0', port=5000)
