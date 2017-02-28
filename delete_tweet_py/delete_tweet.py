#!/usr/bin/env python

import os
import time
import datetime
import random
import urllib
import urllib2
import base64
import hmac
import hashlib
import json
# References:
# https://dev.twitter.com/oauth/overview/authorizing-requests

CONSUMER_KEY = os.environ.get("PROMPTWEET_CONSUMER_KEY")
CONSUMER_SECRET = os.environ.get("PROMPTWEET_CONSUMER_SECRET")
ACCESS_TOKEN = os.environ.get("PROMPTWEET_ACCESS_TOKEN")
ACCESS_TOKEN_SECRET = os.environ.get("PROMPTWEET_ACCESS_TOKEN_SECRET")

STATUS_EXPIRED_TIME = 60 * 30
REPLY_EXPIRED_TIME = 60 * 60 * 24


def generate_nonce(length=8):
    """
    Generate pseudorandom number
    from python-oauth2
    http://stackoverflow.com/questions/5590170/what-is-the-standard-method-for-generating-a-nonce-in-python
    """
    return ''.join([str(random.randint(0, 9)) for i in range(length)])


def generate_authorization_header(values):
    header = ""
    for (k, v) in sorted(values.items(), key=lambda x: x[0]):
        header += ", " + k + "=\"" + urllib.quote_plus(v) + "\""
    header = "OAuth " + header[2:]
    return header


def add_oauth_signature(method, url, values):
    sorted_values = sorted(values.items(), key=lambda x: x[0])
    text = method + "&" + urllib.quote_plus(url) + "&" + urllib.quote_plus(urllib.urlencode(sorted_values))
    key = urllib.quote_plus(CONSUMER_SECRET) + "&" + urllib.quote_plus(ACCESS_TOKEN_SECRET)
    signature = base64.b64encode(hmac.new(key, text, hashlib.sha1).digest())
    values["oauth_signature"] = signature
    return values


def post(method, url):
    values = {
        "oauth_consumer_key": CONSUMER_KEY,
        "oauth_signature_method": "HMAC-SHA1",
        "oauth_timestamp": str(int(time.time())),
        "oauth_nonce": generate_nonce(),
        "oauth_version": "1.0",
        "oauth_token": ACCESS_TOKEN,
    }

    values = add_oauth_signature(method, url, values)
    authorization_header = generate_authorization_header(values)

    request = urllib2.Request(url)
    if method == "POST":
        request.get_method = lambda: "POST"
    request.add_header("Authorization", authorization_header)
    return urllib2.urlopen(request)


result = post("GET", "https://api.twitter.com/1.1/statuses/user_timeline.json")
statuses = json.loads(result.read())

for status in statuses:
    status_id = status['id']

    is_reply = True if status['in_reply_to_user_id'] is not None else False
    created_at = status['created_at']
    # Sun Feb 26 21:57:11 +0000 2017
    utc_created_at = datetime.datetime.strptime(created_at, "%a %b %d %H:%M:%S +0000 %Y")
    utc_now = datetime.datetime.utcnow()
    utc_delta_sec = (utc_now - utc_created_at).total_seconds()

    expired_sec = REPLY_EXPIRED_TIME if is_reply else STATUS_EXPIRED_TIME
    if utc_delta_sec > expired_sec:
        post("POST", "https://api.twitter.com/1.1/statuses/destroy/%s.json" % status_id)
