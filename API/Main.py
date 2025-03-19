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

# 이름 중복 방지를 위한 함수
def generate_unique_nickname(base_name, inventory):
    counter = 1
    unique_name = base_name
    while any(item.get("nickname") == unique_name for item in inventory.values()):
        unique_name = f"{base_name} {counter}"
        counter += 1
    return unique_name

def detect_qr_codes(image):
    decoded_objects = decode(image)
    qr_data = {}
    for obj in decoded_objects:
        qr_text = obj.data.decode("utf-8")  # QR 코드 텍스트 추출
        x, y, w, h = obj.rect
        qr_data[qr_text] = {'x': x, 'y': y}  # QR 텍스트를 키로 사용
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
    JSON 파일에 현재 냉장고 데이터를 저장합니다.
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
    curr_data = detect_qr_codes(curr_image)  # QR 코드 인식 결과: {QR Text: {"x": ..., "y": ...}}

    # 데이터 비교
    added, removed, moved = compare_inventories(prev_data, curr_data)

    # 현재 시각 추가
    current_timestamp = datetime.now().strftime("%Y-%m-%d-%H:%M")  # 타임스탬프 형식 변경

    # 전체 인벤토리 갱신
    for qr_text, value in removed.items():
        if qr_text in inventory:
            inventory[qr_text]["timestamp"] = current_timestamp

    for qr_text, value in added.items():
        added[qr_text]["timestamp"] = current_timestamp
        # 고유한 닉네임 생성
        added[qr_text]["nickname"] = generate_unique_nickname("New Item", inventory)
        added[qr_text]["qr_code"] = qr_text  # QR 텍스트를 저장

    for qr_text, data in moved.items():
        data["current"]["timestamp"] = current_timestamp
        data["current"]["qr_code"] = qr_text  # QR 텍스트를 저장

    inventory.update(added)
    inventory.update({qr_text: data["current"] for qr_text, data in moved.items()})

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
            "nickname": value.get("nickname", "N/A"),
            "x": value["x"],
            "y": value["y"],
            "timestamp": value.get("timestamp", "N/A"),
            "qr_code": value.get("qr_code", "N/A")  # QR 텍스트 포함
        }
        for key, value in inventory.items()
    }
    return jsonify(inventory_with_timestamps)

@app.route('/rename/<qr_code>/<new_name>', methods=['POST'])
def rename(qr_code, new_name):
    """
    별명명 변경 엔드포인트.
    URL 경로에서 qr_code와 new_name을 받아 inventory를 업데이트합니다.
    """
    # JSON 파일에서 데이터 로드
    inventory = load_inventory()

    # QR 코드로 항목 찾기
    item_to_update = None
    for key, value in inventory.items():
        if value.get("qr_code") == qr_code:
            item_to_update = key
            break

    if item_to_update:
        # 닉네임 업데이트
        inventory[item_to_update]["nickname"] = new_name

        # 변경된 데이터를 JSON 파일에 저장
        save_inventory(inventory)

        return jsonify({"message": "Nickname updated successfully.", "inventory": inventory})
    else:
        return jsonify({"error": f"Item with QR code '{qr_code}' not found."}), 404

@app.route('/reset', methods=['POST'])
def reset_inventory():
    """
    저장된 inventory_data.json 파일을 초기화하는 엔드포인트.
    """
    # 빈 딕셔너리로 초기화
    empty_inventory = {}
    save_inventory(empty_inventory)  # JSON 파일 초기화

    return jsonify({"message": "Inventory has been reset.", "inventory": empty_inventory})

@app.route('/shutdown', methods=['POST'])
def shutdown():
    os.kill(os.getpid(), signal.SIGINT)
    return "Server shutting down..."

if __name__ == '__main__':
    app.run(debug=True)

#if __name__ == '__main__':
#    app.run(host='0.0.0.0', port=9064, debug=True)