import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

os.environ["SQLALCHEMY_DATABASE_URI"] = "sqlite://"
from app import app, db
from Models.Users import User
from Models.Contestant import Contestant

app.config["TESTING"] = True

import pytest


@pytest.fixture
def client():
    return app.test_client()


@pytest.fixture
def app_context():
    with app.app_context():
        yield


def test_database_initialization(app_context):
    users = User.query.all()
    assert len(users) == 4
    assert users[0].user == "sergio"

    contestants = Contestant.query.all()
    assert len(contestants) == 4
    assert contestants[0].name == "cantante1"


def test_user_authentication_persistence(client, app_context):
    user = User.query.filter_by(user="sergio").first()
    assert user is not None
    assert user.password == "sergio"

    r = client.post("/api/login", json={"user": "sergio", "password": "sergio"})
    assert r.status_code == 200
    data = r.get_json()
    assert data["user"]["user"] == "sergio"


def test_vote_persistence_in_database(client, app_context):
    contestant = Contestant.query.get(1)
    initial_votes = contestant.votes

    r = client.post("/api/vote", json={"participantId": 1})
    assert r.status_code == 200

    contestant = Contestant.query.get(1)
    assert contestant.votes == initial_votes + 1


def test_multiple_votes_increment_correctly(client, app_context):
    contestant = Contestant.query.get(2)
    initial_votes = contestant.votes

    for _ in range(5):
        r = client.post("/api/vote", json={"participantId": 2})
        assert r.status_code == 200

    contestant = Contestant.query.get(2)
    assert contestant.votes == initial_votes + 5


def test_results_reflect_database_state(client, app_context):
    contestant = Contestant.query.get(3)
    contestant.votes = 42
    db.session.commit()

    r = client.get("/api/results")
    assert r.status_code == 200
    data = r.get_json()

    contestant_result = next((c for c in data if c["participantId"] == 3), None)
    assert contestant_result is not None
    assert contestant_result["votes"] == 42


def test_all_users_can_authenticate(client):
    users = ["sergio", "ivan", "koldo", "jose"]

    for username in users:
        r = client.post("/api/login", json={"user": username, "password": username})
        assert r.status_code == 200
        data = r.get_json()
        assert data["mensaje"] == "Login exitoso"
        assert data["user"]["user"] == username


def test_participants_endpoint_returns_all_contestants(client):
    r = client.get("/api/participants")
    assert r.status_code == 200
    data = r.get_json()

    assert len(data) == 4
    names = [c["name"] for c in data]
    assert "cantante1" in names
    assert "cantante2" in names
    assert "cantante3" in names
    assert "cantante4" in names


def test_vote_for_all_contestants(client, app_context):
    for contestant_id in range(1, 5):
        contestant = Contestant.query.get(contestant_id)
        initial_votes = contestant.votes

        r = client.post("/api/vote", json={"participantId": contestant_id})
        assert r.status_code == 200

        contestant = Contestant.query.get(contestant_id)
        assert contestant.votes == initial_votes + 1


def test_login_validation_error_messages(client):
    r = client.post("/api/login", json={"user": "sergio"})
    assert r.status_code == 400
    data = r.get_json()
    assert "errores" in data
    assert "password" in data["errores"]


def test_vote_validation_error_messages(client):
    r = client.post("/api/vote", json={})
    assert r.status_code == 400
    data = r.get_json()
    assert "errores" in data
    assert "participantId" in data["errores"]


def test_contestant_not_found_with_negative_id(client):
    r = client.post("/api/vote", json={"participantId": -1})
    assert r.status_code in [400, 404]


def test_contestant_not_found_with_large_id(client):
    r = client.post("/api/vote", json={"participantId": 9999})
    assert r.status_code == 404


def test_results_structure_validation(client):
    r = client.get("/api/results")
    assert r.status_code == 200
    data = r.get_json()

    for result in data:
        assert "participantId" in result
        assert "votes" in result
        assert isinstance(result["participantId"], int)
        assert isinstance(result["votes"], int)
        assert result["votes"] >= 0


def test_participants_structure_validation(client):
    r = client.get("/api/participants")
    assert r.status_code == 200
    data = r.get_json()

    for participant in data:
        assert "id" in participant
        assert "name" in participant
        assert "votes" in participant
        assert isinstance(participant["id"], int)
        assert isinstance(participant["name"], str)
        assert isinstance(participant["votes"], int)
