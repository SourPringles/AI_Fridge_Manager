
from flask import Blueprint
from .connectionTest import connectionTest_bp

# Blueprint 등록
def test_bluprints(app):
    app.register_blueprint(connectionTest_bp)