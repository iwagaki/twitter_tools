#!/usr/bin/env python

import os
import time
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

# from python-oauth2 
# http://stackoverflow.com/questions/5590170/what-is-the-standard-method-for-generating-a-nonce-in-python
def generate_nonce(length = 8):
    """Generate pseudorandom number."""
    return ''.join([str(random.randint(0, 9)) for i in range(length)])


def generate_authorization_header(values):
    header = ""
    for (k, v) in sorted(values.items(), key = lambda x: x[0]):
        header += ", " + k + "=\"" + urllib.quote_plus(v) + "\""
    header = "OAuth " + header[2:]
    return header

def add_oauth_signature(method, url, values):
    sorted_values = sorted(values.items(), key = lambda x: x[0])
    text = method + "&" + urllib.quote_plus(url) + "&" + urllib.quote_plus(urllib.urlencode(sorted_values))
    key = urllib.quote_plus(CONSUMER_SECRET) + "&" + urllib.quote_plus(ACCESS_TOKEN_SECRET)
    signature = base64.b64encode(hmac.new(key, text, hashlib.sha1).digest())
    values["oauth_signature"] = signature
    return values


def post(method, url):
    values = {
        "oauth_consumer_key" : CONSUMER_KEY,
        "oauth_signature_method" : "HMAC-SHA1",
        "oauth_timestamp" : str(int(time.time())),
        "oauth_nonce" : generate_nonce(),
        "oauth_version" : "1.0",
        "oauth_token" : ACCESS_TOKEN,
    }

    values = add_oauth_signature(method, url, values)
    authorization_header = generate_authorization_header(values)

    request = urllib2.Request(url)
    if method == "POST":
        request.get_method = lambda: "POST"
    print request.get_method()
    request.add_header("Authorization", authorization_header)
    return urllib2.urlopen(request)
    

# Test
result = post("GET", "https://api.twitter.com/1.1/statuses/user_timeline.json")
     
statuses = json.loads(result.read())

for status in statuses:
    status_id = status['id']
    
    url = "https://api.twitter.com/1.1/statuses/destroy/%s.json" % status_id
    print url
    print post("POST", url);
