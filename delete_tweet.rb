#!/usr/bin/ruby -Ku
# -*- coding: utf-8 -*-
#
# Copyright (c) 2010 iwagaki@users.sourceforge.net
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'rubygems'
require 'oauth'
require 'json'
require 'open-uri'
require 'pp'

CONSUMER_KEY = ENV['PROMPTWEET_CONSUMER_KEY']
CONSUMER_SECRET = ENV['PROMPTWEET_CONSUMER_SECRET']
ACCESS_TOKEN = ENV['PROMPTWEET_ACCESS_TOKEN']
ACCESS_TOKEN_SECRET = ENV['PROMPTWEET_ACCESS_TOKEN_SECRET']

consumer = OAuth::Consumer.new(
  CONSUMER_KEY,
  CONSUMER_SECRET,
  :site => 'http://twitter.com'
)

access_token = OAuth::AccessToken.new(
  consumer,
  ACCESS_TOKEN,
  ACCESS_TOKEN_SECRET
)

loop do
  begin
    response = access_token.get("http://twitter.com/statuses/user_timeline.json?count=200")
    # TODO: is it ok for fixed count?
  rescue
    break
  end

  begin
    JSON.parse(response.body).each_with_index do |status, index|
      user = status['user']['screen_name']
      status_id = status['id']
      ctime = Time.parse(status['created_at'])
      th = Time.now - 60*60*8
      if (th > ctime)
        puts "#{index}: #{user}:#{status_id}:#{ctime} #{status['text']}" if $DEBUG
        begin
          access_token.post("http://twitter.com/statuses/destroy/#{status_id}.json")
          sleep 2
        rescue
          sleep 5
        end
      end
    end
  rescue
    break
  end
  break
end
