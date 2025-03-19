import os
import json

DATA_FILE = "inventory_data.json"

def load_inventory():
    if os.path.exists(DATA_FILE):
        with open(DATA_FILE, "r") as file:
            try:
                return json.load(file)
            except json.JSONDecodeError:
                return {}
    return {}

def save_inventory(data):
    with open(DATA_FILE, "w") as file:
        json.dump(data, file, indent=4)

def generate_unique_nickname(base_name, inventory):
    counter = 1
    unique_name = base_name
    while any(item.get("nickname") == unique_name for item in inventory.values()):
        unique_name = f"{base_name} {counter}"
        counter += 1
    return unique_name