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
    client.say(channel:data.channel, text:"#{match['expression']}")
  end

  #Quote Route
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

  #Search for a quote route
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

  #Add a quote route
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

  #This exists in case the quote DB is modified directly, to make sure the IDs aren't out of sync
  match /^!reparsequotedb/ do |client, data, match|
    yml = YAML.load_file 'quotes.yml'
    yml2 = {}
    File.open("quotes.yml", "w") do |file|
      yml.keys.each_with_index do |var,i|
        yml2[i] = yml[var]
      end
      file.write(yml2.to_yaml)
    end
    r.size = yml.size
    client.say(channel:data.channel, text: "Reparsed DB")
  end

  #Lewd.png
  match /^!infidel/ do |client, data, match|
    client.say(channel:data.channel, text: "http://i0.kym-cdn.com/photos/images/original/000/690/931/412.png")
  end

  #Karma Change
  match /(?<name><?@?\w+>?)(?<op>\+\+|--)/ do |client, data, match|
    if "<@#{data.user}>" != match[:name] #Don't let someone change their own karma
      name = match[:name]
      yml = YAML.load_file 'karma.yml'
      File.open('karma.yml', 'w') do |file|
        if match[:op] == '++'
          yml[name].nil? ? yml[name] = 1 : yml[name] += 1
        else
          yml[name].nil? ? yml[name] = -1 : yml[name] -= 1
        end
        file.write(yml.to_yaml)
      end
      client.say(channel:data.channel, text:"#{name} new karma count: #{yml[name]}")
    else
      client.say(channel:data.channel, text:"That's not allowed #{match[:name]} :grumpy_cat:") #grumpy_cat for people trying to mess with their own karma.
    end
  end

  #All the bot-chan karma commands
  command 'karma' do |client, data, match|
    if match['expression'].nil? #karma with no args is basically help
      client.say(channel:data.channel, text:"Karma what? :confused:")
      client.say(channel:data.channel, text:"Usage: bot-chan karma <best>|<worst> [<user>|<thing>]\nUsage: bot-chan karma <user>|<thing>")
    else
      exparr = match['expression'].split #mark args an array
      if exparr[1].nil?
        yml = YAML.load_file 'karma.yml'
        if exparr[0] == "best"
          sorted = yml.sort_by { |user, karma| karma }
          client.say(channel:data.channel, text:"Top 5 Karma
          1. #{sorted[-1][0]}: #{sorted[-1][1]}
          2. #{sorted[-2][0]}: #{sorted[-2][1]}
          3. #{sorted[-3][0]}: #{sorted[-3][1]}
          4. #{sorted[-4][0]}: #{sorted[-4][1]}
          5. #{sorted[-5][0]}: #{sorted[-5][1]}")
        elsif exparr[0] == "worst"
          sorted = yml.sort_by { |user, karma| karma }
          client.say(channel:data.channel, text:"Bottom 5 Karma
          1. #{sorted[0][0]}: #{sorted[0][1]}
          2. #{sorted[1][0]}: #{sorted[1][1]}
          3. #{sorted[2][0]}: #{sorted[2][1]}
          4. #{sorted[3][0]}: #{sorted[3][1]}
          5. #{sorted[4][0]}: #{sorted[4][1]}")
        elsif yml.key?(exparr[0])
          client.say(channel:data.channel, text:"#{exparr[0]} karma: #{yml[exparr[0]]}")
        else
          client.say(channel:data.channel, text:"Karma what? :confused:")
          client.say(channel:data.channel, text:"Usage: bot-chan karma <best>|<worst> [<user>|<thing>]\nUsage: bot-chan karma <user>|<thing>")
        end
      else
        if exparr[0] == "best"
          if exparr[1] == "user"
            yml = YAML.load_file 'karma.yml'
            yml.delete_if { |key, value| key !~ /^<@\w+>$/ } #Remove non-users
            sorted = yml.sort_by { |user, karma| karma }
            client.say(channel:data.channel, text:"Top 5 User Karma
            1. #{sorted[-1][0]}: #{sorted[-1][1]}
            2. #{sorted[-2][0]}: #{sorted[-2][1]}
            3. #{sorted[-3][0]}: #{sorted[-3][1]}
            4. #{sorted[-4][0]}: #{sorted[-4][1]}
            5. #{sorted[-5][0]}: #{sorted[-5][1]}")
          elsif exparr[1] == "thing"
            yml = YAML.load_file 'karma.yml'
            yml.delete_if { |key, value| key =~ /^<@\w+>$/ } #Remove non-things
            sorted = yml.sort_by { |user, karma| karma }
            client.say(channel:data.channel, text:"Top 5 Thing Karma
            1. #{sorted[-1][0]}: #{sorted[-1][1]}
            2. #{sorted[-2][0]}: #{sorted[-2][1]}
            3. #{sorted[-3][0]}: #{sorted[-3][1]}
            4. #{sorted[-4][0]}: #{sorted[-4][1]}
            5. #{sorted[-5][0]}: #{sorted[-5][1]}")
          else
            client.say(channel:data.channel, text:"Karma what? :confused:")
            client.say(channel:data.channel, text:"Usage: bot-chan karma <best>|<worst> [<user>|<thing>]\nUsage: bot-chan karma <user>|<thing>")
          end
        elsif exparr[0] == "worst"
          if exparr[1] == "user"
            yml = YAML.load_file 'karma.yml'
            yml.delete_if { |key, value| key !~ /^<@\w+>$/ }
            sorted = yml.sort_by { |user, karma| karma }
            client.say(channel:data.channel, text:"Bottom 5 User Karma
            1. #{sorted[0][0]}: #{sorted[0][1]}
            2. #{sorted[1][0]}: #{sorted[1][1]}
            3. #{sorted[2][0]}: #{sorted[2][1]}
            4. #{sorted[3][0]}: #{sorted[3][1]}
            5. #{sorted[4][0]}: #{sorted[4][1]}")
          elsif exparr[1] == "thing"
            yml = YAML.load_file 'karma.yml'
            yml.delete_if { |key, value| key =~ /^<@\w+>$/ }
            sorted = yml.sort_by { |user, karma| karma }
            client.say(channel:data.channel, text:"Bottom 5 Thing Karma
            1. #{sorted[0][0]}: #{sorted[0][1]}
            2. #{sorted[1][0]}: #{sorted[1][1]}
            3. #{sorted[2][0]}: #{sorted[2][1]}
            4. #{sorted[3][0]}: #{sorted[3][1]}
            5. #{sorted[4][0]}: #{sorted[4][1]}")
          else
            client.say(channel:data.channel, text:"Karma what? :confused:")
            client.say(channel:data.channel, text:"Usage: bot-chan karma <best>|<worst> [<user>|<thing>]\nUsage: bot-chan karma <user>|<thing>")
          end
        else
          client.say(channel:data.channel, text:"Karma what? :confused:")
          client.say(channel:data.channel, text:"Usage: bot-chan karma <best>|<worst> [<user>|<thing>]\nUsage: bot-chan karma <user>|<thing>")
        end
      end
    end
  end
end
BotChan.run
