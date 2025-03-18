from flask import Flask, request, jsonify
import cv2
import numpy as np
import os
import signal
from ultralytics import YOLO
from pyzbar.pyzbar import decode
from datetime import datetime

app = Flask(__name__)

# YOLOv8 모델 로드 (사전 학습된 모델 사용 또는 사용자 정의 모델)
model = YOLO('yolov8n.pt')

# 식료품 및 위치 정보 저장소 (임시)
inventory = {}

# 이전 이미지 저장 경로 설정
PREV_IMAGE_PATH = "./prev_image.jpg"

# 중복된 이름을 방지하는 함수
def generate_unique_name(base_name, inventory):
    count = 1
    new_name = base_name
    while new_name in inventory:
        count += 1
        new_name = f"{base_name}_{count}"
    return new_name

def detect_qr_codes(image):
    decoded_objects = decode(image)
    qr_data = {}
    for i, obj in enumerate(decoded_objects):
        x, y, w, h = obj.rect
        qr_data[f"Item{i+1}"] = {'x': x, 'y': y}
    return qr_data

def compare_inventories(prev_data, curr_data):
    added = {key: curr_data[key] | {"timestamp": datetime.now().isoformat()} for key in curr_data if key not in prev_data}
    removed = {key: prev_data[key] | {"timestamp": datetime.now().isoformat()} for key in prev_data if key not in curr_data}
    moved = {
        key: {
            "previous": {"x": prev_data[key]["x"], "y": prev_data[key]["y"]},
            "current": {"x": curr_data[key]["x"], "y": curr_data[key]["y"]},
            "timestamp": datetime.now().isoformat()
        } for key in curr_data 
        if key in prev_data and curr_data[key] != prev_data[key]
    }
    return added, removed, moved

@app.route('/upload', methods=['POST'])
def upload():
    curr_img = request.files.get('curr_image')
    name_changes = request.form.get('name_changes')

    if not curr_img:
        return jsonify({"error": "Current image is required."}), 400

    curr_image = cv2.imdecode(np.frombuffer(curr_img.read(), np.uint8), cv2.IMREAD_COLOR)

    # 이전 이미지 로드
    if os.path.exists(PREV_IMAGE_PATH):
        prev_image = cv2.imread(PREV_IMAGE_PATH)
        prev_data = detect_qr_codes(prev_image)
    else:
        prev_data = {}

    # QR코드 인식 (현재 이미지)
    curr_data = detect_qr_codes(curr_image)

    # 이름 변경 처리
    if name_changes:
        name_changes = eval(name_changes)  # string to dict
        for old_name, new_name in name_changes.items():
            if new_name in inventory:
                new_name = generate_unique_name(new_name, inventory)
            if old_name in curr_data:
                curr_data[new_name] = curr_data.pop(old_name)

    # 현재 이미지를 저장하여 다음 비교에 사용
    cv2.imwrite(PREV_IMAGE_PATH, curr_image)

    # 데이터 비교
    added, removed, moved = compare_inventories(prev_data, curr_data)

    # 전체 인벤토리 갱신
    for key, value in removed.items():
        if key in inventory:
            inventory[key]["timestamp"] = value["timestamp"]

    inventory.update(added)
    inventory.update({key: data["current"] for key, data in moved.items()})

    return jsonify({
        "added": added,
        "removed": removed,
        "moved": moved,
        "inventory": inventory
    })

@app.route('/inventory', methods=['GET'])
def get_inventory():
    return jsonify(inventory)

@app.route('/shutdown', methods=['POST'])
def shutdown():
    os.kill(os.getpid(), signal.SIGINT)
    return "Server shutting down..."

if __name__ == '__main__':
    app.run(debug=True)
