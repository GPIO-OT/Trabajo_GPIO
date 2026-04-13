import os

from db import db
from Models.Users import User
from Models.Contestant import Contestant
from flask import Flask, jsonify, request
from flasgger import Swagger, swag_from
from marshmallow import ValidationError
from schemas import LoginSchema, VoteSchema
from swagger_config import swagger_config
from swagger_template import swagger_template
from flask_cors import CORS

app = Flask(__name__)
uri = os.getenv("SQLALCHEMY_DATABASE_URI")
if not uri:
    db_user = os.getenv("MYSQL_USER", "root")
    db_password = os.getenv("MYSQL_PASSWORD", "sergio2525")
    db_host = os.getenv("MYSQL_HOST", "localhost")
    db_name = os.getenv("MYSQL_DATABASE", "OT_BD")
    uri = f"mysql+pymysql://{db_user}:{db_password}@{db_host}:3306/{db_name}"
app.config["SQLALCHEMY_DATABASE_URI"] = uri
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

db.init_app(app)

with app.app_context():
    db.create_all()

    if User.query.count() == 0:
        users = [
            User(user="sergio", password="sergio"),
            User(user="ivan", password="ivan"),
            User(user="koldo", password="koldo"),
            User(user="jose", password="jose"),
        ]
        db.session.add_all(users)
        db.session.commit()
        print("✅ 4 usuarios insertados")
    else:
        print("⚠️ Usuarios ya existen, no se insertaron")

    if Contestant.query.count() == 0:
        contestant = [
            Contestant(name="cantante1", votes=0),
            Contestant(name="cantante2", votes=0),
            Contestant(name="cantante3", votes=0),
            Contestant(name="cantante4", votes=0),
        ]
        db.session.add_all(contestant)
        db.session.commit()
        print("✅ 4 concursantes insertados")
    else:
        print("⚠️ Concursantes ya existen, no se insertaron")

CORS(app)

swagger = Swagger(app, config=swagger_config, template=swagger_template)


@app.route("/", methods=["GET"])
@swag_from("swaggerDocs/conexion.yml")
def conexion():
    try:
        return jsonify({"Mensaje": "Hola mundo"}), 200
    except Exception as e:
        return (
            jsonify({"mensaje": "Error al conectarse al endpoint", "error": str(e)}),
            500,
        )


@app.route("/login", methods=["POST"])
@swag_from("swaggerDocs/login.yml")
def login():
    try:
        data = LoginSchema().load(request.get_json() or {})
    except ValidationError as e:
        return jsonify({"mensaje": "Datos inválidos", "errores": e.messages}), 400
    user = User.query.filter_by(user=data["user"], password=data["password"]).first()
    if not user:
        return jsonify({"mensaje": "Credenciales incorrectas"}), 401
    return jsonify({"mensaje": "Login exitoso", "user": user.to_dict()}), 200


@app.route("/participants", methods=["GET"])
@swag_from("swaggerDocs/participants.yml")
def get_participants():
    contestants = Contestant.query.all()
    return jsonify([c.to_dict() for c in contestants]), 200


@app.route("/results", methods=["GET"])
@swag_from("swaggerDocs/results.yml")
def get_results():
    contestants = Contestant.query.all()
    return (
        jsonify([{"participantId": c.id, "votes": c.votes} for c in contestants]),
        200,
    )


@app.route("/vote", methods=["POST"])
@swag_from("swaggerDocs/vote.yml")
def vote():
    try:
        data = VoteSchema().load(request.get_json() or {})
    except ValidationError as e:
        return jsonify({"mensaje": "Datos inválidos", "errores": e.messages}), 400
    contestant = Contestant.query.get(data["participantId"])
    if not contestant:
        return jsonify({"mensaje": "Concursante no encontrado"}), 404
    contestant.votes += 1
    db.session.commit()
    return jsonify({"mensaje": "Voto registrado"}), 200


if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5003)
