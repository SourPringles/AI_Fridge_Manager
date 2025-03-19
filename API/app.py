from flask import Flask
from views.upload import upload_bp
from views.inventory import inventory_bp
from views.rename import rename_bp
from views.reset import reset_bp
from db.userdata_db import init_db

app = Flask(__name__)

# Initialize the database
init_db()

# 블루프린트 등록
app.register_blueprint(upload_bp)
app.register_blueprint(inventory_bp)
app.register_blueprint(rename_bp)
app.register_blueprint(reset_bp)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)