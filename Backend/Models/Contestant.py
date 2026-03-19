from sqlalchemy import Column, Integer, String
from db import db

class Contestant(db.Model):
    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(50))
    votes = Column(Integer)
    def __repr__(self):
        return f'<Contestant {self.name!r}>'
    
    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'votes': self.votes,
        }