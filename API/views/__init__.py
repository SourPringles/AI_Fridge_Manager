
from flask import Blueprint
from .upload import upload_bp
from .inventory import inventory_bp
from .rename import rename_bp
from .reset import reset_bp

# Blueprint 등록
def register_blueprints(app):
    app.register_blueprint(upload_bp)
    app.register_blueprint(inventory_bp)
    app.register_blueprint(rename_bp)
    app.register_blueprint(reset_bp)