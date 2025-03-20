from flask import Blueprint, request, jsonify
from db import load_inventory, save_inventory

rename_bp = Blueprint('rename', __name__)

@rename_bp.route('/rename/<qr_code>/<new_name>', methods=['POST'])
def rename(qr_code, new_name):
    # SQL 조회로 최신 인벤토리 반환
    inventory = load_inventory()

    # QR 코드로 항목 찾기
    if qr_code in inventory:
        inventory[qr_code]["nickname"] = new_name
        save_inventory(qr_code, inventory[qr_code])
        inventory = load_inventory()
        return jsonify({"message": "Nickname updated successfully.", "inventory": inventory})
    else:
        return jsonify({"error": f"Item with QR code '{qr_code}' not found."}), 404