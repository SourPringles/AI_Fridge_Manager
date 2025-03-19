from flask import Blueprint, request, jsonify
from utils.helpers import generate_unique_nickname
from utils.qr_utils import detect_qr_codes, compare_inventories
from db.userdata_db import load_inventory, save_inventory, delete_inventory
from datetime import datetime
import cv2
import numpy as np

upload_bp = Blueprint('upload', __name__)

@upload_bp.route('/upload', methods=['POST'])
def upload():
    curr_img = request.files.get('curr_image')

    if not curr_img:
        return jsonify({"error": "Current image is required."}), 400

    curr_image = cv2.imdecode(np.frombuffer(curr_img.read(), np.uint8), cv2.IMREAD_COLOR)

    # 이전 데이터 로드
    inventory = load_inventory()
    prev_data = inventory.copy()

    # QR코드 인식
    curr_data = detect_qr_codes(curr_image)

    # 데이터 비교
    added, removed, moved = compare_inventories(prev_data, curr_data)

    # 현재 시각 추가
    current_timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    # 전체 인벤토리 갱신
    for qr_text, value in removed.items():
        delete_inventory(qr_text)

    for qr_text, value in added.items():
        if qr_text not in inventory:
            new_item = {
                "x": value["x"],
                "y": value["y"],
                "lastModified": current_timestamp,
                "nickname": generate_unique_nickname("New Item", inventory)
            }
            save_inventory(qr_text, new_item)

    for qr_text, data in moved.items():
        if qr_text in inventory:
            updated_item = {
                "x": data["current"]["x"],
                "y": data["current"]["y"],
                "lastModified": current_timestamp,
                "nickname": inventory[qr_text]["nickname"]
            }
            save_inventory(qr_text, updated_item)

    return jsonify({
        "added": added,
        "removed": removed,
        "moved": moved,
    })