from flask import Blueprint, jsonify
from db import delete_inventory, load_inventory

reset_bp = Blueprint('reset', __name__)

@reset_bp.route('/reset', methods=['POST'])
def reset_inventory():
    delete_inventory("*")  # Clear all entries in the database
    inventory = load_inventory()
    return jsonify({"message": "Inventory has been reset.", "inventory": inventory})