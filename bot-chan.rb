#!/usr/bin/env ruby

#require junk
require 'rubygems'
require 'slack-ruby-bot'
require 'yaml'
require './random.rb'




class BotChan < SlackRubyBot::Bot
  #Seed RNG
  tempyaml = YAML.load_file 'quotes.yml'
  r = Rand.new(tempyaml.size)

  #Ping Test
  command 'ping' do |client, data, match|
    client.say(channel:data.channel, text: "pong" )
  end

  #Quote Route
  #match /^!quote ?(?<qid>\d*)$/ do |client, data, match|
  match /^!quote ?(?<qid>\S+)?$/ do |client, data, match|
    yml = YAML.load_file 'quotes.yml' #Open quotes
    if match[:qid].nil? #Generate random if not specified
      num = r.next
    else
      num = match[:qid].to_i
      if num < 0 #Check for negative number
        num = yml.count + match[:qid].to_i
      end
    end
    response = yml[num]
    if response.nil?
      client.say(channel:data.channel, text:"I was unable to find a quote with ID #{num}, therefore I am generating a random quote instead.")
      num = r.next
      response = yml[num]
    end
    client.say(channel:data.channel, text:"Quote ID #{num}: #{response}") #output quote
  end

  match /^!grepquote (?<needle>.*)$/ do |client, data, match|
    yml = YAML.load_file 'quotes.yml'
    cnt = 0
    yml.each_pair do |key, value| #Iterate though the quotes
      if value.downcase =~ /#{match[:needle].downcase}/
        cnt += 1
      end
    end
    if cnt == 0
      client.say(channel:data.channel, text:"No matches found for #{match[:needle]}, try again.")
    elsif cnt < 10 #Prevent flooding the channel. Maybe should be lower?
      yml.each_pair do |key, value|
        if value.downcase =~ /#{match[:needle].downcase}/
          client.say(channel:data.channel, text:"Match Found. ID: #{key}, Quote: #{value}")
        end
      end
    else
      client.say(channel:data.channel, text:"More then 10 matches found, please limit your search")
    end
  end

  match /^!(addquote|quoteadd) (?<quote>.*)$/ do |client, data, match|
    yml = YAML.load_file 'quotes.yml'
    size = yml.size
  	File.open("quotes.yml", "w") do |file|
      yml[size] = match[:quote]
      file.write(yml.to_yaml)
      end
  	r.size = yml.size
  	client.say(channel:data.channel, text:"Quote had been added as Quote ID #{size}!")
  end
end
BotChan.run
