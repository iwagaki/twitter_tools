#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# $:.unshift '/usr/local/rvm/gems/ruby-1.9.3-p194/gems/oauth-0.4.7/lib/'

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

class TwitterSession
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
    return get("https://api.twitter.com/1.1/statuses/user_timeline.json?count=#{count}")
  end

  def delete_status(status_id)
    return post("https://api.twitter.com/1.1/statuses/destroy/#{status_id}.json")
  end

  def delete(tweet)
    return delete_status(tweet.get_status_id)
  end
end

def main
  twitter_session = TwitterSession.new

  loop do
    begin
      # TODO: is it ok to use a fixed count?
      response = twitter_session.get_user_timeline(200)
      break if not response.instance_of? Net::HTTPOK
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
            twitter_session.delete(tweet)
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
