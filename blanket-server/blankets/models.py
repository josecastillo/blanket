from blankets import app
from .util import gen_salt, is_equal

from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.dialects import postgresql
from _hashlib import openssl_sha256

import datetime
import os

__author__ = 'Joey Castillo'

app.config.from_pyfile('blankets.cfg')
app.config['SQLALCHEMY_DATABASE_URI'] = os.environ['DATABASE_URL']
db = SQLAlchemy(app)

class Channel(db.Model):
    id = db.Column(postgresql.UUID, primary_key=True)
    salt = db.Column(db.String(32))
    access_hash = db.Column(db.String(64))
    closed = db.Column(db.Boolean)
    last_message = db.Column(db.DateTime, nullable=True)

    def __init__(self, id, access_code):
        self.id = id
        self.salt = gen_salt(32)
        self.access_hash = openssl_sha256(self.salt + access_code).hexdigest()
        self.closed = False
        self.last_message = datetime.datetime.utcnow()

    def verify_access(self, access_code):
        hash = openssl_sha256(self.salt + access_code).hexdigest()
        return is_equal(str(hash), str(self.access_hash))

class Message(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    channel_id = db.Column(postgresql.UUID, db.ForeignKey('channel.id'))
    data = db.Column(postgresql.BYTEA)
    nonce = db.Column(postgresql.BYTEA)
    timestamp = db.Column(db.DateTime)

    def __init__(self, channel_id, data, nonce):
        self.channel_id = channel_id
        self.data = data
        self.nonce = nonce
        self.timestamp = datetime.datetime.utcnow()
