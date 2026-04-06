from flask import Flask, render_template, request, jsonify, session, redirect, url_for, flash
import time
from datetime import datetime
from functools import wraps
import os

app = Flask(__name__)
app.secret_key = os.urandom(24)  # 用于会话加密

# 存储服务器数据
vps_data = {}

# 管理员账号配置（实际项目中应该使用数据库存储）
ADMIN_USERNAME = "admin"
ADMIN_PASSWORD = "admin123"  # 建议修改成强密码

# 登录验证装饰器
def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'logged_in' not in session:
            if request.is_json:
                return jsonify({"status": "error", "message": "未登录"}), 401
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function

@app.route('/')
def index():
    now = time.time()
    total_in = 0.0
    total_out = 0.0
    online_count = 0
    
    for sid in vps_data:
        if now - vps_data[sid]['last_seen'] > 30:
            vps_data[sid]['online'] = False
        else:
            vps_data[sid]['online'] = True
            online_count += 1
        
        # 计算总流量
        if 'net_total_in' in vps_data[sid]:
            try:
                total_in += float(vps_data[sid]['net_total_in'].replace('GB', ''))
            except:
                pass
        if 'net_total_out' in vps_data[sid]:
            try:
                total_out += float(vps_data[sid]['net_total_out'].replace('GB', ''))
            except:
                pass
    
    total_in = round(total_in, 2)
    total_out = round(total_out, 2)
    total_all = round(total_in + total_out, 2)
    
    return render_template('index.html', servers=vps_data, logged_in=session.get('logged_in', False), 
                           total_in=total_in, total_out=total_out, total_all=total_all, online_count=online_count)

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        
        if username == ADMIN_USERNAME and password == ADMIN_PASSWORD:
            session['logged_in'] = True
            session['username'] = username
            return redirect(url_for('index'))
        else:
            flash('用户名或密码错误', 'error')
    
    return render_template('login.html')

@app.route('/logout')
def logout():
    session.pop('logged_in', None)
    session.pop('username', None)
    return redirect(url_for('index'))

@app.route('/settings', methods=['GET', 'POST'])
@login_required
def settings():
    # 声明全局变量
    global ADMIN_USERNAME, ADMIN_PASSWORD
    
    if request.method == 'POST':
        current_username = request.form.get('current_username')
        current_password = request.form.get('current_password')
        new_username = request.form.get('new_username')
        new_password = request.form.get('new_password')
        
        # 验证当前账号密码
        if current_username != ADMIN_USERNAME or current_password != ADMIN_PASSWORD:
            flash('当前用户名或密码错误', 'error')
            return render_template('settings.html', current_username=ADMIN_USERNAME)
        
        # 更新账号密码
        if new_username:
            ADMIN_USERNAME = new_username
        if new_password:
            ADMIN_PASSWORD = new_password
        
        # 更新会话中的用户名
        session['username'] = ADMIN_USERNAME
        
        flash('账号密码修改成功！', 'success')
        return redirect(url_for('index'))
    
    return render_template('settings.html', current_username=ADMIN_USERNAME)

@app.route('/api/report', methods=['POST'])
def report():
    data = request.json
    server_id = data.get('id')
    if not server_id:
        return jsonify({"status": "error", "message": "Missing ID"}), 400
    
    # 保留已修改的服务器名称
    if server_id in vps_data and 'name' in vps_data[server_id]:
        data['name'] = vps_data[server_id]['name']
    
    data['last_seen'] = time.time()
    data['online'] = True
    data['last_seen_fmt'] = datetime.fromtimestamp(data['last_seen']).strftime('%H:%M:%S')
    vps_data[server_id] = data
    return jsonify({"status": "success"})

# 修改服务器名称（需要登录）
@app.route('/api/server/<server_id>/rename', methods=['POST'])
@login_required
def rename_server(server_id):
    data = request.json
    new_name = data.get('name')
    
    if not new_name:
        return jsonify({"status": "error", "message": "名称不能为空"}), 400
    
    if server_id in vps_data:
        vps_data[server_id]['name'] = new_name
        return jsonify({"status": "success", "message": "名称修改成功"})
    else:
        return jsonify({"status": "error", "message": "服务器不存在"}), 404

# 删除服务器（需要登录）
@app.route('/api/server/<server_id>', methods=['DELETE'])
@login_required
def delete_server(server_id):
    if server_id in vps_data:
        del vps_data[server_id]
        return jsonify({"status": "success", "message": "服务器已删除"})
    else:
        return jsonify({"status": "error", "message": "服务器不存在"}), 404

# 获取服务器列表（用于管理）
@app.route('/api/servers')
@login_required
def get_servers():
    return jsonify(vps_data)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
