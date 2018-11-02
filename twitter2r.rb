require 'rubygems'
require 'csv'
require 'whatlanguage'
#require 'stopwords'
#require 'bing_translator'

class Twitter2R
#put all csv into an array
	def merge_tweets
	    @wl = WhatLanguage.new(:all) ##instantiate language checker
  ##instantiate language checker
	   files = Dir.glob("#{ARGV.first}/*.csv")
	   #file = "#{ARGV.first}"
	   get_tweet_text(files)
	end

#get message for each tweet
	def get_tweet_text(files)
		#tweets_file = "#{ARGV.last}_merged.csv"
		tweets_file = ARGV.last
		CSV.open(tweets_file, 'ab') do |csv|
			begin
				new_file = CSV.read(tweets_file,:encoding => "iso-8859-1",:col_sep => ",")
			  	if new_file.none?
			    	csv << ["id", "created_at", "tweet", "user_id", "username", "screen_name", "hashtags", "retweets", "urls", "media", "quoted_text"]
			  	end
				files.each do |file|
					CSV.foreach(file, headers:true) do |tweet|
						begin
							langauge = tweet['tweet'].gsub(/http(:|s:)(\/\/|\/)[A-Za-z\S]+/, "").gsub(/http(s:|:)\u2026/, "").gsub(/(@|#)[a-zA-Z]*/, "").gsub(/^RT/, "").gsub(/[^0-9a-zA-Z ]/, "").strip
							if !langauge.empty?						
								#if @wl.detect(langauge) == :en
								if @wl.process_text(langauge)[:english] >= 2
									puts tweet
									puts '-----------------------'
									csv << [tweet['id'], tweet['created_at'], tweet['tweet'], tweet['user_id'], tweet['username'], tweet['screen_name'], tweet['hashtags'], tweet['retweeted_tweet_retweet_count'], tweet['urls'], tweet['media'], tweet['quoted_text']]
								end
							end		
						rescue Exception => e
	  						puts "Error #{e}"
	  						next	
						end	
					end	
				end
			rescue Exception => e
	  			puts "Error #{e}"
	  			next
	  		end	
  		end
	end
		
end

csv = Twitter2R.new
csv.merge_tweets
