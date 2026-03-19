from sqlalchemy import Column, Integer, String
from db import db

class User(db.Model):
    id = Column(Integer, primary_key=True, autoincrement=True)
    user = Column(String(50), unique=True)
    password = Column(String(10), unique=True)
    def __repr__(self):
        return f'<User {self.user!r}>'
    
    def to_dict(self):
        return {
            'id': self.id,
            'user': self.user,
            'password': self.password,
        }