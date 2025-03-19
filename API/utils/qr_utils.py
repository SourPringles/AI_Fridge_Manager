from pyzbar.pyzbar import decode

def detect_qr_codes(image):
    decoded_objects = decode(image)
    qr_data = {}
    for obj in decoded_objects:
        qr_text = obj.data.decode("utf-8")
        x, y, w, h = obj.rect
        qr_data[qr_text] = {'x': x, 'y': y}
    return qr_data

def compare_inventories(prev_data, curr_data, tolerance=5):
    from datetime import datetime
    added = {key: curr_data[key] | {"lastModified": datetime.now().strftime("%Y-%m-%d %H:%M:%S")} for key in curr_data if key not in prev_data}
    removed = {key: prev_data[key] | {"lastModified": datetime.now().strftime("%Y-%m-%d %H:%M:%S")} for key in prev_data if key not in curr_data}
    moved = {
        key: {
            "previous": {"x": prev_data[key]["x"], "y": prev_data[key]["y"]},
            "current": {"x": curr_data[key]["x"], "y": curr_data[key]["y"]},
            "lastModified": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        }
        for key in curr_data
        if key in prev_data and (
            abs(curr_data[key]["x"] - prev_data[key]["x"]) > tolerance or
            abs(curr_data[key]["y"] - prev_data[key]["y"]) > tolerance
        )
    }
    return added, removed, moved