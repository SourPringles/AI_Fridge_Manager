import os
import json
from datetime import datetime

# JSON 파일 로드 함수(미사용)
#DATA_FILE = "inventory_data.json"
#
#def load_inventory():
#    if os.path.exists(DATA_FILE):
#        with open(DATA_FILE, "r") as file:
#            try:
#                return json.load(file)
#            except json.JSONDecodeError:
#                return {}
#    return {}
# JSON 파일 저장 함수(미사용)
#def save_inventory(data):
#    with open(DATA_FILE, "w") as file:
#        json.dump(data, file, indent=4)

def generate_unique_nickname(base_name, inventory):
    counter = 1
    unique_name = base_name
    while any(item.get("nickname") == unique_name for item in inventory.values()):
        unique_name = f"{base_name} {counter}"
        counter += 1
    return unique_name

def save_log(action, **data):
    """
    로그 저장 함수
    """
    logs_dir = os.path.join(os.getcwd(), 'Logs')
    os.makedirs(logs_dir, exist_ok=True)
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    log_file_path = os.path.join(logs_dir, f'{timestamp}.txt')

    # 로그 파일 작성
    with open(log_file_path, 'w') as log_file:
        log_file.write(f"{action} at {timestamp}\n")
        for key, value in data.items():
            log_file.write(f"{key.capitalize()}: {value}\n")

    # 로그 파일 정리
    log_amount = 5 # 최대 로그 파일 개수

    log_files = sorted(
        [os.path.join(logs_dir, f) for f in os.listdir(logs_dir) if f.endswith('.txt')],
        key=os.path.getmtime
    )
    while len(log_files) > log_amount:
        os.remove(log_files.pop(0))