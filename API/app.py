from flask import Flask
from views import register_blueprints
from test import test_bluprints
from db import init_db

app = Flask(__name__)

# Initialize the database
init_db()

# Register blueprints
register_blueprints(app)
test_bluprints(app)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=9064, debug=True)