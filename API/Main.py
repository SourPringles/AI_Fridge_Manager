from flask import Flask, request, jsonify
import cv2
import numpy as np
import os
import signal
from ultralytics import YOLO
from pyzbar.pyzbar import decode
from datetime import datetime
import json

app = Flask(__name__)

# YOLOv8 모델 로드 (사전 학습된 모델 사용 또는 사용자 정의 모델)
model = YOLO('yolov8n.pt')

# 식료품 및 위치 정보 저장소 (임시)
inventory = {}

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

DATA_FILE = "inventory_data.json"  # JSON 파일 경로

def load_inventory():
    """
    JSON 파일에서 냉장고 데이터를 로드합니다.
    파일이 없으면 빈 딕셔너리를 반환합니다.
    """
    if os.path.exists(DATA_FILE):
        with open(DATA_FILE, "r") as file:
            try:
                return json.load(file)
            except json.JSONDecodeError:
                # JSON 파일이 손상된 경우 빈 딕셔너리를 반환
                return {}
    return {}

def save_inventory(data):
    """
    냉장고 데이터를 JSON 파일에 저장합니다.
    """
    with open(DATA_FILE, "w") as file:
        json.dump(data, file, indent=4)

@app.route('/upload', methods=['POST'])
def upload():
    curr_img = request.files.get('curr_image')
    name_changes = request.form.get('name_changes')

    if not curr_img:
        return jsonify({"error": "Current image is required."}), 400

    curr_image = cv2.imdecode(np.frombuffer(curr_img.read(), np.uint8), cv2.IMREAD_COLOR)

    # 이전 데이터 로드 (JSON 파일에서 불러오기)
    inventory = load_inventory()  # JSON 파일에서 현재 인벤토리 로드
    prev_data = inventory.copy()  # 이전 데이터를 불러옴

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

    # 데이터 비교
    added, removed, moved = compare_inventories(prev_data, curr_data)

    # 현재 시각 추가
    current_timestamp = datetime.now().strftime("%Y-%m-%d-%H-%M")  # 타임스탬프 형식 변경

    # 전체 인벤토리 갱신
    for key, value in removed.items():
        if key in inventory:
            inventory[key]["timestamp"] = current_timestamp

    for key, value in added.items():
        added[key]["timestamp"] = current_timestamp

    for key, data in moved.items():
        data["current"]["timestamp"] = current_timestamp

    inventory.update(added)
    inventory.update({key: data["current"] for key, data in moved.items()})

    # 변경된 데이터를 JSON 파일에 저장
    save_inventory(inventory)

    return jsonify({
        "added": added,
        "removed": removed,
        "moved": moved,
        "inventory": inventory
    })


@app.route('/inventory', methods=['GET'])
def get_inventory():
    # JSON 파일에서 데이터를 로드
    inventory = load_inventory()

    inventory_with_timestamps = {
        key: {
            "x": value["x"],
            "y": value["y"],
            "timestamp": value.get("timestamp", "N/A")
        }
        for key, value in inventory.items()
    }
    return jsonify(inventory_with_timestamps)

@app.route('/shutdown', methods=['POST'])
def shutdown():
    os.kill(os.getpid(), signal.SIGINT)
    return "Server shutting down..."

#if __name__ == '__main__':
#    app.run(debug=True)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=9064, debug=True)