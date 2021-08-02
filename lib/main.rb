# frozen_string_literal: true

require "twitter"
require "yaml"

module Main
  class Error < StandardError; end
  class Bot
    def initialize
      @config = {}
    end

    def authorize
      setcreds = ->(client) {
        client.consumer_key = @config["consumer_key"]
        client.consumer_secret = @config["consumer_secret"]
        client.access_token = @config["access_token"]
        client.access_token_secret = @config["access_token_secret"]
      }
      @client = Twitter::Streaming::Client.new({}, &setcreds)
      # @type [Twitter::REST::Client]
      @rclient = Twitter::REST::Client.new({}, &setcreds)
    end

    def start
      @config = YAML.load(File.open("config.yml", "r").read)
      puts @config
      authorize
      @client.filter(track: "ist das denn", &method(:handle_tweet)) 
    end

    # @param tweet [Twitter::Tweet] 
    # @param word [String]
    def reply( tweet, word )
      pct = rand(100)
      @rclient.update("@#{tweet.user.screen_name} \n Das ist #{pct}%#{word}.\n#{"🟩"* ( pct / 10 )  + "⬜" * (10-( pct / 10))}", {:in_reply_to_status => tweet})
    end

    # @param tweet [Twitter::Tweet] 
    def handle_tweet( tweet )
      raise ArgumentError.new "Not a tweet" unless tweet.is_a?(Twitter::Tweet)
      match = tweet.text.downcase.match(/wie((?: +[^.;!? ]+)+) +ist +das +denn(?:,? *bitte)?/)
      if match && !tweet.retweet?
        word = match.captures[0]
        reply(tweet, word)
      end
    end    
  end
end

bot = Main::Bot.new
bot.start