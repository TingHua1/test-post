from flask import Flask, render_template, request, jsonify
import time
from datetime import datetime

app = Flask(__name__)

vps_data = {}

@app.route('/')
def index():
    now = time.time()
    for sid in vps_data:
        if now - vps_data[sid]['last_seen'] > 30:
            vps_data[sid]['online'] = False
        else:
            vps_data[sid]['online'] = True
    return render_template('index.html', servers=vps_data)

@app.route('/api/report', methods=['POST'])
def report():
    data = request.json
    server_id = data.get('id')
    if not server_id:
        return jsonify({"status": "error", "message": "Missing ID"}), 400
    
    data['last_seen'] = time.time()
    data['online'] = True
    data['last_seen_fmt'] = datetime.fromtimestamp(data['last_seen']).strftime('%H:%M:%S')
    vps_data[server_id] = data
    return jsonify({"status": "success"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
