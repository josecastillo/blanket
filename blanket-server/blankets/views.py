from . import app
from .models import db
from .models import Channel, Message
from .errors import error_message

from flask import request, jsonify

import base64
import time
import datetime

__author__ = 'castillo'

def generate_response(payload_dict=None, error=None, status_code=200):
    response_dict = dict()

    if not error:
        response_dict['success'] = True
    else:
        response_dict['success'] = False
        response_dict['error'] = error
    if payload_dict:
        response_dict['payload'] = payload_dict

    response = jsonify(response_dict)
    response.status_code = status_code
    if status_code == 401:
        response.headers['WWW-Authenticate'] = 'Basic realm="Login Required"'

    return response


@app.route('/v1/channel/open', methods=['POST'])
def channel_open():
    if not request.authorization:
        return generate_response(status_code=401, error=error_message.NO_AUTHENTICATION)

    channel_id = request.authorization.username
    try:
        channel = Channel.query.get(channel_id)
    except:
        return generate_response(status_code=500, error=error_message.INTERNAL_SERVER_ERROR)

    if channel and not channel.verify_access(request.authorization.password):
        return generate_response(status_code=403, error=error_message.UNAUTHORIZED)

    if not channel:
        channel = Channel(channel_id, request.authorization.password)
        db.session.add(channel)
        try:
            db.session.commit()
        except:
            return generate_response(status_code=500, error=error_message.INTERNAL_SERVER_ERROR)

    return generate_response(status_code=201, payload_dict={'closed' : channel.closed, 'last_update' : int(time.mktime(channel.last_message.timetuple()))})


@app.route('/v1/channel/close', methods=['POST'])
def channel_close():
    if not request.authorization:
        return generate_response(status_code=401, error=error_message.NO_AUTHENTICATION)

    channel_id = request.authorization.username
    try:
        channel = Channel.query.get(channel_id)
    except:
        return generate_response(status_code=500, error=error_message.INTERNAL_SERVER_ERROR)

    if not channel:
        return generate_response(status_code=404, error=error_message.CHANNEL_NOT_FOUND)

    if channel.verify_access(request.authorization.password):
        if not channel.closed:
            channel.closed = True
            channel.last_message = datetime.datetime.utcnow()
            db.session.add(channel)
            try:
                db.session.commit()
            except Exception as e:
                return generate_response(status_code=500, error=error_message.INTERNAL_SERVER_ERROR + e.message)
        return generate_response({'closed' : channel.closed, 'last_update' : int(time.mktime(channel.last_message.timetuple()))})


    return generate_response(status_code=403, error=error_message.UNAUTHORIZED)


@app.route('/v1/channel', methods=['POST'])
def channel_status():
    if not request.authorization:
        return generate_response(status_code=401, error=error_message.NO_AUTHENTICATION)

    channel_id = request.authorization.username
    try:
        channel = Channel.query.get(channel_id)
    except:
        return generate_response(status_code=500, error=error_message.INTERNAL_SERVER_ERROR)

    if not channel:
        return generate_response(status_code=404, error=error_message.CHANNEL_NOT_FOUND)
    if channel.verify_access(request.authorization.password):
        return generate_response({'closed' : channel.closed, 'last_update' : int(time.mktime(channel.last_message.timetuple()))})

    return generate_response(status_code=403, error=error_message.UNAUTHORIZED)


@app.route('/v1/message', methods=['POST'])
def message_list():
    if not request.authorization:
        return generate_response(status_code=401, error=error_message.NO_AUTHENTICATION)

    channel_id = request.authorization.username
    try:
        channel = Channel.query.get(channel_id)
    except:
        return generate_response(status_code=500, error=error_message.INTERNAL_SERVER_ERROR)

    if not channel:
        return generate_response(status_code=404, error=error_message.CHANNEL_NOT_FOUND)
    if channel.closed:
        return generate_response(status_code=403, error=error_message.CHANNEL_CLOSED)

    if channel.verify_access(request.authorization.password):
        since = datetime.datetime.fromtimestamp(int(request.json['since']))
        messages = Message.query.filter(Message.channel_id == channel.id).filter(Message.timestamp >= since)
        payload_dict = {'messages' : []}
        for message in messages:
            payload_dict['messages'].append({
                'timestamp' : int(time.mktime(message.timestamp.timetuple())),
                'data' : base64.b64encode(message.data),
                'nonce' : base64.b64encode(message.nonce)
            })
        payload_dict['last_update'] = int(time.mktime(datetime.datetime.utcnow().timetuple()))
        return generate_response(payload_dict)

    return generate_response(status_code=403, error=error_message.UNAUTHORIZED)


@app.route('/v1/message/create', methods=['POST'])
def message_create():
    if not request.authorization:
        return generate_response(status_code=401, error=error_message.NO_AUTHENTICATION)

    channel_id = request.authorization.username
    try:
        channel = Channel.query.get(channel_id)
    except:
        return generate_response(status_code=500, error=error_message.INTERNAL_SERVER_ERROR)

    if not channel:
        return generate_response(status_code=404, error=error_message.CHANNEL_NOT_FOUND)
    if channel.closed:
        return generate_response(status_code=403, error=error_message.CHANNEL_CLOSED)

    message = Message(channel_id,
                      base64.b64decode(request.json['message']),
                      base64.b64decode(request.json['nonce']))
    channel = Channel.query.get(message.channel_id)
    channel.last_message = datetime.datetime.utcnow()
    db.session.add(message)
    db.session.add(channel)
    try:
        db.session.commit()
    except:
        return generate_response(status_code=500, error=error_message.INTERNAL_SERVER_ERROR)

    return generate_response(status_code=201, payload_dict={'timestamp' : int(time.mktime(message.timestamp.timetuple()))})
