from flask import Flask
from .routes import api_blueprint
from .auth.routes import auth_blueprint

def create_app():
    app = Flask(__name__)

    app.register_blueprint(api_blueprint, url_prefix='/api')
    app.register_blueprint(auth_blueprint, url_prefix='/auth')
    return app
