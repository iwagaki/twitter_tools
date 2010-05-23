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

# TODO Make some class after proto-typing

require 'gtk2'
#require 'net/http'
require 'rubygems'
require 'oauth'
require 'json'
require 'open-uri'
require 'pstore'

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

# TODO Learn how to make document by rdoc
#
# test function
# [val1] importance
# [val2] test3
# 
#  test(1,2)
# def test(val1, val2)
#   exit
# end

Gtk.init

window = Gtk::Window.new();
window.signal_connect('delete_event') { Gtk::main_quit }
#window.signal_connect('destroy') { Gtk::main_quit }

window.keep_above = true
window.set_title('Promptweet')
window.set_default_size(500,-1)

window.move((Gdk.screen_width - window.default_width) / 2, (Gdk.screen_height - window.default_height) / 2)

file = __FILE__
file = File.readlink(file) if File.ftype(__FILE__) == 'link'
dir = File.dirname(file)
icon_pixbuf = Gdk::Pixbuf.new("#{dir}/icon.ico")
icon_list = [icon_pixbuf]
Gtk::Window.set_default_icon_list(icon_list)

icon_db = PStore.new("#{dir}/icon.db")

#window.set_position(Gtk::WIN_POS_CENTER)
window.signal_connect('key_press_event') do |widget, event|
  case event.keyval
    when Gdk::Keyval::GDK_Escape then Gtk::main_quit
  end
end

vbox = Gtk::VBox.new

#model = Gtk::ListStore.new(String,String)
#model = Gtk::ListStore.new(Gdk::Pixbuf,String,String)
model = Gtk::ListStore.new(Gdk::Pixbuf,String)
@lst = Gtk::TreeView.new(model)
@lst.headers_visible = false
# @list.set_rules_hint(true)


# loader = Gdk::PixbufLoader.new
# open("http://a1.twimg.com/profile_images/68878254/DSC04338_normal.JPG") { |f|
#   loader.last_write(f.read)
# }
# pixbuf = loader.pixbuf

# column.pack_start(render_pixbuf,expand=False)
# column.add_attribute(render_pixbuf,'pixbuf',c.COL_ICON)
# render_text = gtk.CellRendererText()
# column.pack_start(render_text,expand=True)
# column.add_attribute(render_text,'text',c.COL_TEXT)
# self.append_column(column)

renderer0 = Gtk::CellRendererPixbuf.new
renderer0.yalign = 0
renderer0.set_property('cell-background', '#000000')

#renderer0.background = '#e0e0ff'
column1   = Gtk::TreeViewColumn.new('icon',renderer0,'pixbuf' => 0) \
  .set_fixed_width(48) \
  .set_min_width(1) \
  .set_sizing(Gtk::TreeViewColumn::AUTOSIZE)

column1.set_cell_data_func(renderer0) {|column, cell, model, iter|
  cell.set_property('cell-background', '#ffffff')

  # Gtk::TreeModel::Path path = m_liststore->get_path( it );
  # if !(path[ 0 ] % 3) {
  #     cell->property_cell_background_gdk() = Gdk::Color( "blue" );
}

@lst.append_column(column1)

#renderer1.expander=true

# column1   = Gtk::TreeViewColumn.new('friends',renderer1,'text' => 0) \
#   .set_fixed_width(10) \
#   .set_min_width(1) \
#   .set_sizing(Gtk::TreeViewColumn::AUTOSIZE)
# @lst.append_column(column1)

# renderer1 = Gtk::CellRendererText.new
# renderer1.set_wrap_mode(Pango::Layout::WRAP_WORD)
# renderer1.set_wrap_width(500)
# renderer1.weight = Pango::WEIGHT_BOLD
# column3 = Gtk::TreeViewColumn.new('user',renderer1,'markup' => 1) \
#   .set_fixed_width(10) \
#   .set_min_width(1) \
#   .set_sizing(Gtk::TreeViewColumn::AUTOSIZE)
# @lst.append_column(column3)

renderer2 = Gtk::CellRendererText.new
#renderer2.expander=true
renderer2.set_wrap_mode(Pango::Layout::WRAP_WORD)
renderer2.set_wrap_width(500-55)
#renderer2.background = '#0084b4'
#column2   = Gtk::TreeViewColumn.new('tweet',renderer2,'text' => 2) \
column2   = Gtk::TreeViewColumn.new('tweet',renderer2,'markup' => 1) \
                .set_fixed_width(500-55) \
                .set_min_width(1) \
                .set_sizing(Gtk::TreeViewColumn::AUTOSIZE)
@lst.append_column(column2)

replies_thread = nil
delete_queue = Queue.new

entry = Gtk::Entry.new
#entry.set_text("Input your tweet.")
entry.max_length = 144
# set_max_byte
entry.signal_connect("activate") {
  mystatus = entry.text
  entry.set_text("")
  model.clear
  @lst.hide_all
  window.resize(500,1)

  if mystatus == ""
    Gtk::main_quit
  else
#    response = access_token.get('http://twitter.com/statuses/friends_timeline.json')
    count = 0

    # FIXME Re-condier how to use thread or timeout
    Gtk.timeout_add(1000) {

      replies_thread = Thread.new do
        # puts "start to get replies"
        response = access_token.get('http://twitter.com/statuses/replies.json?count=5')
        JSON.parse(response.body).each do |status|
          # puts "!!"
          user = status['user']
          # puts "#{user['name']}(#{user['screen_name']}): #{status['text']}"
          #puts "#{user['profile_image_url']}"
          
          image_url = user['profile_image_url']
          model = @lst.model
          iter = model.append

          loader = Gdk::PixbufLoader.new

          icon_db.transaction do
            if icon_db.root?(image_url)
              image = icon_db[image_url]
              loader.last_write(image)
#              puts "using cache #{image_url}"
            else
              open(image_url) { |f|
                image = f.read
                icon_db[image_url] = image
                loader.last_write(image)
#                puts "cacheed #{image_url}"
              }
            end
          end
          # puts "end to get replies"

          pixbuf = loader.pixbuf
          loader.close

          iter.set_value(0, pixbuf)
          # iter.set_value(1, "<big><b><span foreground=\"blue\">#{user['screen_name']}</span></b></big>")
          iter.set_value(1, "<b><span foreground=\"blue\">#{user['screen_name']}</span></b> #{status['text']}")

          count += 1
          if count >= 5
            break
          end
          @lst.show_all
        end

      end
      false
    }

    if !$DEBUG
      post_thread = Thread.new do
        # puts "start to post"
        response = access_token.post(
                                     'http://twitter.com/statuses/update.json',
                                     'status'=> "#{mystatus}"
                                     )
        status = JSON.parse(response.body)
        # puts "end to post"
        # TODO Make an option to get entire friend timeline
        # TODO Make an option to disable auto-deleting for specific tweet
        # TODO Make if-condition to disable auto-deleting for replies
        status_id = status['id']
        delete_queue.push(status_id)
        Gtk.timeout_add(5*60000) {
          status_id = delete_queue.pop
          response = access_token.post(
                                       "http://twitter.com/statuses/destroy/#{status_id}.json"
                                       )
          false
        }

        false
      end
    end


    # req = Net::HTTP::Post.new("/statuses/update.xml")
    # req.basic_auth ENV['TWITTER_USERNAME'], ENV['TWITTER_PASSWORD']
    # Net::HTTP.start("twitter.com") {|http|
    #   response = http.request(req, "status=#{status}")
      # if response != Net::HTTPSuccess
      #   print response.error!
      # end
    # }
  end
}

# clist = Gtk::CList.new(["Name", "Tweet"])
vbox.pack_start(entry)
#vbox.pack_start(pixbuf)
vbox.pack_start(@lst)
window.add(vbox)
window.show_all

Gtk.main
