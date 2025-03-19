from flask import Blueprint, jsonify
from db.userdata_db import load_inventory

inventory_bp = Blueprint('inventory', __name__)

@inventory_bp.route('/inventory', methods=['GET'])
def get_inventory():
    inventory = load_inventory()

    inventory_with_timestamps = {
        key: {
            "nickname": value.get("nickname", "N/A"),
            "x": value["x"],
            "y": value["y"],
            "lastModified": value.get("lastModified", "N/A"),
            "qr_code": key
        }
        for key, value in inventory.items()
    }
    return jsonify(inventory_with_timestamps)