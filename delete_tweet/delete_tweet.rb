#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
#
# Copyright (c) 2010-2012 iwagaki@users.sourceforge.net
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

EXPIRED_TIME = 60 * 60 * 24

class Tweet
  def initialize(status)
    @status = status
  end

  def get_status_id
    return @status['id']
  end

  def get_user
    return @status['user']['screen_name']
  end

  def get_created_time
    return Time.parse(@status['created_at'])
  end

  def is_expired(second)
    return (Time.now - second > get_created_time)
  end
end

class TwitterCtrl
  def initialize
    consumer = OAuth::Consumer.new(CONSUMER_KEY,
                                   CONSUMER_SECRET,
                                   :site => 'http://twitter.com')

    @access_token = OAuth::AccessToken.new(consumer,
                                          ACCESS_TOKEN,
                                          ACCESS_TOKEN_SECRET)
    raise unless @access_token != nil
  end

  def get(url)
    return @access_token.get(url)
  end

  def post(url)
    return @access_token.post(url)
  end

  def get_user_timeline(count)
    return get("http://twitter.com/statuses/user_timeline.json?count=#{count}")
  end

  def delete_status(status_id)
    return post("http://twitter.com/statuses/destroy/#{status_id}.json")
  end

  def delete(tweet)
    return delete_status(tweet.get_status_id)
  end
end

def main
  ctrl = TwitterCtrl.new

  loop do
    begin
      response = ctrl.get_user_timeline(200)
      # TODO: is it ok to use a fixed count?
    rescue
      break
    end

    begin
      JSON.parse(response.body).each_with_index do |status, index|
        tweet = Tweet.new(status)
        if (tweet.is_expired(EXPIRED_TIME))
          user = tweet.get_user
          status_id = tweet.get_status_id
          ctime = tweet.get_created_time
          puts "#{index}: #{user}:#{status_id}:#{ctime} #{status['text']}" if $DEBUG
          begin
            ctrl.delete(tweet)
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
end

if __FILE__ == $0
  main
end
