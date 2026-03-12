import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

os.environ["SQLALCHEMY_DATABASE_URI"] = "sqlite://"
from app import app

app.config["TESTING"] = True

import pytest


@pytest.fixture
def client():
    return app.test_client()


def test_conexion(client):
    r = client.get("/")
    assert r.status_code == 200
    assert r.get_json()["Mensaje"] == "Hola mundo"


def test_login_exitoso(client):
    r = client.post("/api/login", json={"user": "sergio", "password": "sergio"})
    assert r.status_code == 200
    assert r.get_json()["mensaje"] == "Login exitoso"


def test_login_credenciales_incorrectas(client):
    r = client.post("/api/login", json={"user": "x", "password": "y"})
    assert r.status_code == 401


def test_login_datos_invalidos(client):
    r = client.post("/api/login", json={})
    assert r.status_code == 400


def test_get_participants(client):
    r = client.get("/api/participants")
    assert r.status_code == 200
    data = r.get_json()
    assert len(data) == 4
    assert data[0]["name"] == "cantante1"


def test_get_results(client):
    r = client.get("/api/results")
    assert r.status_code == 200
    data = r.get_json()
    assert len(data) == 4
    assert "participantId" in data[0] and "votes" in data[0]


def test_vote_ok(client):
    r = client.post("/api/vote", json={"participantId": 1})
    assert r.status_code == 200
    assert r.get_json()["mensaje"] == "Voto registrado"


def test_vote_concursante_no_encontrado(client):
    r = client.post("/api/vote", json={"participantId": 999})
    assert r.status_code == 404


def test_vote_datos_invalidos(client):
    r = client.post("/api/vote", json={})
    assert r.status_code == 400
