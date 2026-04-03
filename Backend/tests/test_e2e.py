import sys
import os
import threading
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

os.environ["SQLALCHEMY_DATABASE_URI"] = "sqlite://"
from app import app, db
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


def test_complete_user_flow_login_to_vote(client):
    r = client.post("/api/login", json={"user": "sergio", "password": "sergio"})
    assert r.status_code == 200
    assert r.get_json()["mensaje"] == "Login exitoso"

    r = client.get("/api/participants")
    assert r.status_code == 200
    participants = r.get_json()
    assert len(participants) > 0
    first_participant_id = participants[0]["id"]

    r = client.post("/api/vote", json={"participantId": first_participant_id})
    assert r.status_code == 200
    assert r.get_json()["mensaje"] == "Voto registrado"

    r = client.get("/api/results")
    assert r.status_code == 200
    results = r.get_json()
    voted_result = next(
        (res for res in results if res["participantId"] == first_participant_id), None
    )
    assert voted_result is not None
    assert voted_result["votes"] > 0


def test_multiple_users_voting_workflow(client):
    users = ["sergio", "ivan", "koldo", "jose"]
    participant_id = 1

    for user in users:
        r = client.post("/api/login", json={"user": user, "password": user})
        assert r.status_code == 200

        r = client.post("/api/vote", json={"participantId": participant_id})
        assert r.status_code == 200

    r = client.get("/api/results")
    assert r.status_code == 200
    results = r.get_json()
    voted_result = next((res for res in results if res["participantId"] == participant_id), None)
    assert voted_result["votes"] >= len(users)


def test_voting_for_all_participants_and_verify_results(client, app_context):
    r = client.get("/api/participants")
    participants = r.get_json()

    votes_per_participant = {}
    for participant in participants:
        pid = participant["id"]
        votes_count = (pid % 3) + 1
        votes_per_participant[pid] = votes_count

        for _ in range(votes_count):
            r = client.post("/api/vote", json={"participantId": pid})
            assert r.status_code == 200

    r = client.get("/api/results")
    results = r.get_json()

    for result in results:
        pid = result["participantId"]
        expected_votes = votes_per_participant.get(pid, 0)
        actual_votes = result["votes"]
        assert actual_votes >= expected_votes


def test_multiple_rapid_votes_same_participant(client, app_context):
    participant_id = 2
    num_votes = 5

    with app.app_context():
        initial_contestant = Contestant.query.get(participant_id)
        initial_votes = initial_contestant.votes

    for _ in range(num_votes):
        r = client.post("/api/vote", json={"participantId": participant_id})
        assert r.status_code == 200
        assert r.get_json()["mensaje"] == "Voto registrado"

    with app.app_context():
        final_contestant = Contestant.query.get(participant_id)
        expected_votes = initial_votes + num_votes
        assert (
            final_contestant.votes == expected_votes
        ), f"Expected {expected_votes} votes, got {final_contestant.votes}"


def test_invalid_login_then_valid_login_workflow(client):
    r = client.post("/api/login", json={"user": "invalid", "password": "wrong"})
    assert r.status_code == 401

    r = client.post("/api/login", json={"user": "sergio", "password": "sergio"})
    assert r.status_code == 200
    assert r.get_json()["mensaje"] == "Login exitoso"


def test_vote_invalid_then_valid_participant(client):
    r = client.post("/api/vote", json={"participantId": 999})
    assert r.status_code == 404

    r = client.post("/api/vote", json={"participantId": 1})
    assert r.status_code == 200


def test_results_consistency_after_multiple_operations(client, app_context):
    r = client.get("/api/results")
    initial_results = r.get_json()
    initial_total_votes = sum(res["votes"] for res in initial_results)

    votes_to_add = 15
    for i in range(votes_to_add):
        participant_id = (i % 4) + 1
        r = client.post("/api/vote", json={"participantId": participant_id})
        assert r.status_code == 200

    r = client.get("/api/results")
    final_results = r.get_json()
    final_total_votes = sum(res["votes"] for res in final_results)

    assert final_total_votes == initial_total_votes + votes_to_add


def test_api_endpoints_availability(client):
    endpoints = [
        ("/", "GET"),
        ("/api/participants", "GET"),
        ("/api/results", "GET"),
    ]

    for endpoint, method in endpoints:
        if method == "GET":
            r = client.get(endpoint)
            assert r.status_code == 200


def test_edge_case_empty_json_payloads(client):
    r = client.post("/api/login", json={})
    assert r.status_code == 400

    r = client.post("/api/vote", json={})
    assert r.status_code == 400


def test_edge_case_malformed_json(client):
    r = client.post("/api/login", data="not json", content_type="application/json")
    assert r.status_code in [400, 500]

    r = client.post("/api/vote", data="not json", content_type="application/json")
    assert r.status_code in [400, 500]


def test_voting_boundary_values(client):
    r = client.post("/api/vote", json={"participantId": 0})
    assert r.status_code in [400, 404]

    r = client.post("/api/vote", json={"participantId": -1})
    assert r.status_code in [400, 404]

    r = client.post("/api/vote", json={"participantId": 999999})
    assert r.status_code == 404


def test_complete_voting_cycle_all_participants(client, app_context):
    r = client.get("/api/participants")
    participants = r.get_json()

    for participant in participants:
        pid = participant["id"]

        with app.app_context():
            contestant = Contestant.query.get(pid)
            initial_votes = contestant.votes

        r = client.post("/api/vote", json={"participantId": pid})
        assert r.status_code == 200

        with app.app_context():
            contestant = Contestant.query.get(pid)
            assert contestant.votes == initial_votes + 1


def test_stress_rapid_sequential_votes(client):
    participant_id = 3
    num_rapid_votes = 50

    for _ in range(num_rapid_votes):
        r = client.post("/api/vote", json={"participantId": participant_id})
        assert r.status_code == 200

    r = client.get("/api/results")
    results = r.get_json()
    voted_result = next((res for res in results if res["participantId"] == participant_id), None)
    assert voted_result["votes"] >= num_rapid_votes


def test_login_response_structure(client):
    r = client.post("/api/login", json={"user": "sergio", "password": "sergio"})
    assert r.status_code == 200
    data = r.get_json()

    assert "mensaje" in data
    assert "user" in data
    assert "user" in data["user"]
    assert data["user"]["user"] == "sergio"


def test_participants_response_completeness(client):
    r = client.get("/api/participants")
    assert r.status_code == 200
    participants = r.get_json()

    assert len(participants) == 4

    for participant in participants:
        assert "id" in participant
        assert "name" in participant
        assert "votes" in participant
        assert participant["name"].startswith("cantante")


def test_results_match_participants(client):
    r = client.get("/api/participants")
    participants = r.get_json()
    participant_ids = {p["id"] for p in participants}

    r = client.get("/api/results")
    results = r.get_json()
    result_ids = {res["participantId"] for res in results}

    assert participant_ids == result_ids
