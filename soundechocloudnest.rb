#!/usr/bin/env ruby

# This is a hack by Hannes Tydén, hannes at soundcloud com, presented at Music Hack Day Berlin, 2009-09-20
# It is released on a strict "works for me" basis.

# Could not get the mix of Ruby gems and my modified code to work.
# Therefore you need to specify the load paths manually.

# Path to the SoundCloud Ruby API Wrapper
$LOAD_PATH << "/opt/lib/ruby/gems/1.8/gems/soundcloud-ruby-api-wrapper-0.4.1/lib"
require "soundcloud"

# Path to the EchoNest Ruby API Wrapper
$LOAD_PATH << "#{File.expand_path("~")}/code/active/ruby-echonest/lib/"
require 'echonest'

begin
  require 'setup'

  KEYS = %w[ C C# D D# E F F# G G# A A# B ]
  MODE = %w[ min maj ]

  ECHONEST_TAGS = %w[ tempo loudness key mode time_signature end_of_fade_in start_of_fade_out ]

  def colorize(text, color_code)
    "\033[#{color_code}m#{text}\033[0m"
  end

  logo = '
     ____                  ______    __        _______             ___  __        __ 
    / __/__  __ _____  ___/ / __/___/ /  ___  / ___/ /__  __ _____/ / |/ /__ ___ / /_
   _\ \/ _ \/ // / _ \/ _  / _// __/ _ \/ _ \/ /__/ / _ \/ // / _  /    / -_|_-</ __/
  /___/\___/\_._/_//_/\_._/___/\__/_//_/\___/\___/_/\___/\_._/\_._/_/|_/\__/___/\__/ 
  '

  rows = logo.split("\n")
  puts colorize(rows[1], "34")
  puts colorize(rows[2], "35")
  puts colorize(rows[3], "36")
  puts colorize(rows[4], "37")

  puts "
  From the Cloud to the Nest and back again.
  "

  SC.connect do |soundcloud, settings|
      me = soundcloud.User.find_me
      puts "Welcome #{me.username}!"
    
      tracks = soundcloud.Track.find(:all, :from => "/me/tracks?filter=streamable,public")
    
      tracks.each_with_index do |track, index|
        puts "#{(index + 1).to_s.rjust(2, " ")} #{track.tag_list =~ /echonest/ ? "*" : "-"} #{track.title} "
      end
    
      puts "Choose a track: (1 - #{tracks.size})"
    
      track_index = gets.strip.to_i
      if track_index > 0 && (track = tracks[track_index - 1])
        track = tracks[track_index - 1]
        echonest = Echonest(settings[:echonest_key])
      
        puts "Asking Echonest to fetch '#{track.title}' for analysis"
        md5 = echonest.request(:upload, :url => track.stream_url)
        puts "Fetch done, analyzing ..."
      
        tags = Hash[*(ECHONEST_TAGS.map do |echonest_tag|
            value = echonest.send("get_#{echonest_tag}", md5)
          
            value = value.value if value.respond_to?(:value)
          
            [ echonest_tag, value ]
          end).flatten]
      
        echonest.send("get_sections", md5).each_with_index do |section, index|
          attrs = {
            :track_id  => track.id,
            :timestamp => section.start.to_f * 1000,
            :body      => "Section #{index + 1}"
          }
        
          soundcloud.Comment.create(attrs)
        end
      
        soundcloud.Comment.create(
          :track_id  => track.id,
          :timestamp => tags["end_of_fade_in"] * 1000,
          :body      => "Now it starts 4 realz"
        )
      
        soundcloud.Comment.create(
          :track_id  => track.id,
          :timestamp => tags["start_of_fade_out"] * 1000,
          :body      => "No more to listen to here, please go away now."
        )
      
        tags["key"]  = KEYS[tags["key"]]
        tags["mode"] = MODE[tags["mode"]]
      
        puts "Updating track"
      
        track.tag_list = tags.map { |echonest_tag, value| "echonest:#{echonest_tag}=#{value}" }.join(" ")
        track.save
      
        puts "Done"
        puts "Go to #{track.permalink_url}? (Yes: y, No: a key)"
        if gets.strip.downcase == "y"
          `open #{track.permalink_url}`
        end
      else
        puts "If you want it that way ..."
      end
  end
rescue Exception => e
  puts "An error occurred:\n#{e}\n"
ensure
  puts "Thank you, good bye!"
end
