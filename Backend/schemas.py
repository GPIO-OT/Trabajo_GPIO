from marshmallow import Schema, fields, validate


class LoginSchema(Schema):
    user = fields.Str(required=True, validate=validate.Length(min=1))
    password = fields.Str(required=True, validate=validate.Length(min=1))


class VoteSchema(Schema):
    participantId = fields.Int(required=True, validate=validate.Range(min=1))
