require 'rubygems'
require 'zlib'
#require 'json'
require 'yajl'
require 'csv'
require 'sanitize'
require 'geocoder'

class TweetFilterReader

### Loads files. After calling the scipt full path to directory where sfm filter files are stores, followed
### by full path, name, and extention to your desired output file (ie, /place/on/filesystem/tweets.csv)
	def readfiles
		@tweets = []
		@files = Dir.glob("#{ARGV.first}/*.gz")
		@files.each do |file|
			puts file
			open_gz(file)
		end
	end

	def open_gz(file)
		tweets_file = ARGV.last
		newfile =  File.new(file)
		if !File.zero?(newfile)
			#puts newfile.inspect
  			gz = Zlib::GzipReader.new(newfile)
  			puts '++++++++++++++++++++++++++++'
  			#puts gz.inspect
  			begin
	  			gz.each_line do |line|
	  				CSV.open(tweets_file, 'ab') do |csv|
		  				begin
						  	file = CSV.read(tweets_file,:encoding => "iso-8859-1",:col_sep => ",")
							  	if file.none?
							    	csv << ["id", "created_at", "tweet", "source", "in_reply_to_id", "in_reply_to_screen_name", "user_id", "username", "screen_name", "user_location", "user_url", "user_description", "user_followers_count", "user_friends_count", "user_lists", "user_favorites_count", "user_tweet_count", "user_signup_date", "user_lang", "tweet_coordinates", "tweet_placename", "tweet_place_country", "tweet_place_bounds", "hashtags", "mentions", "urls", "media", "quoted_date", "quoted_text", "quoted_reply_id", "quoted_reply_name","quoted_from_id", "quoted_user_name", "quoted_user_location", "quoted_user_followers", "quoted_user_friends", "quoted_user_created_at", "quoted_user_lang", "quoted_tweet_coordinates", "quoted_tweet_placename", "quoted_tweet_country", "quoted_tweet_bounds", "quoted_tweet_retweet_count", "quoted_tweet_favorite_count", "quoted_tweet_hashtags", "quoted_tweet_mentions", "quoted_tweet_urls", "quoted_tweet_media", "retweeted_date", "retweeted_text", "retweeted_reply_id", "retweeted_reply_name","retweeted_from_id", "retweeted_user_name", "retweeted_user_location", "retweeted_user_followers", "retweeted_user_friends", "retweeted_user_created_at", "retweeted_user_lang", "retweeted_tweet_coordinates", "retweeted_tweet_placename", "retweeted_tweet_country", "retweeted_tweet_bounds", "retweeted_tweet_retweet_count", "retweeted_tweet_favorite_count", "retweeted_tweet_hashtags", "retweeted_tweet_mentions"]
							  	end
							  	parser = Yajl::Parser.new
							  	tweet = parser.parse(line)
				  				#tweet = JSON.parse(line)
				  				#get_location(tweet['user']['location'])
				  				#@user_location_lat, @user_location_long
				  				#"user_location_long", "user_location_lat"
				  				get_tweet_status(tweet['entities'])
				  				get_quoted_status(tweet['quoted_status'])
				  				get_retweet_status(tweet['retweeted_status'])
				  				get_coordinates(tweet['coordinates'])
				  				get_place(tweet['place'])
				  				#puts tweet['user']['name']
				  				#puts "***********"
				  				csv << [tweet['id'], tweet['created_at'], tweet['text'], Sanitize.fragment(tweet['source']), tweet['in_reply_to_user_id'], tweet['in_reply_to_screen_name'], tweet['user']['id'], tweet['user']['name'], tweet['user']['screen_name'], @user_status, tweet['user']['location'], tweet['user']['url'], tweet['user']['description'], tweet['user']['followers_count'], tweet['user']['friends_count'], tweet['user']['listed_count'], tweet['user']['favourites_count'], tweet['user']['statuses_count'], tweet['user']['created_at'], tweet['user']['lang'], @tweet_coordinates, @tweet_placename, @tweet_place_country, @tweet_place_bounds, @tweet_hashtags, @tweet_mentions, @tweet_urls, @tweet_media, @quoted_date, @quoted_text, @quoted_reply_id, @quoted_reply_name, @quoted_from_id, @quoted_from_name, @quoted_from_location, @quoted_followers, @quoted_friends, @quoted_created_at, @quoted_lang, @quoted_coordinates, @quoted_placename, @quoted_place_country, @quoted_place_bounds, @quoted_retweet_count, @quoted_favorite_count, @quoted_hastags, @quoted_mentions, @quoted_urls, @quoted_media, @retweeted_date, @retweeted_text , @retweeted_reply_id, @retweeted_reply_name, @retweeted_from_id, @retweeted_from_name, @retweeted_from_location, @retweeted_followers, @retweeted_friends, @retweeted_created_at, @retweeted_lang, @retweeted_coordinates, @retweeted_placename, @retweeted_place_country, @retweeted_place_bounds, @retweeted_retweet_count, @retweeted_favorite_count, @retweeted_hastags, @retweeted_mentions]
				  		rescue Exception => e
		     				puts "Error #{e}"
		     				next
				  		end
			  		end
	  			end
  			rescue Exception => e
  				puts "Error #{e}"
  			end
		else
			puts "file empty"
		end
		puts "------------"
	end

	def get_coordinates(tweet)
		if !tweet.nil?
			@tweet_coordinates = tweet['coordinates'].to_s.gsub("[","").gsub("]","")
		else
			@tweet_coordinates = nil
		end
	end

	def get_place(tweet)
		if !tweet.nil?
			@tweet_placename = tweet['full_name']
			@tweet_place_country = tweet['country']
			@tweet_place_bounds = tweet['bounding_box']['coordinates'].to_s.gsub("[","").gsub("]","")
		else
			@tweet_placename = nil
			@tweet_place_country = nil
			@tweet_place_bounds = nil
		end
	end


	def get_tweet_status(tweet)
		get_hashtags(tweet['hashtags'])
		@tweet_hashtags = @hashtags
		@tweet_mentions = get_mentions(tweet['user_mentions'])
		@tweet_media = get_media(tweet['media'])
		@tweet_urls = get_urls(tweet['urls'])
	end

	def get_quoted_status(tweet)
		if !tweet.nil?
			@quoted_date = tweet['created_at']
			@quoted_text = tweet['text']
			@quoted_reply_id = tweet['in_reply_to_user_id']
			@quoted_reply_name = tweet['in_reply_to_screen_name']
			@quoted_from_id = tweet['user']['id']
			@quoted_from_name = tweet['user']['name']
			@quoted_from_location = tweet['user']['location']
			@quoted_followers = tweet['user']['followers_count']
			@quoted_friends = tweet['user']['friends_count']
			@quoted_created_at = tweet['user']['created_at']
			@quoted_lang = tweet['user']['lang']
			quoted_coordinates = get_coordinates(tweet['coordinates'])
			@quoted_coordinates = @tweet_coordinates
			quoted_place = get_place(tweet['place'])
			@quoted_placename = @tweet_placename
			@quoted_place_country = @tweet_place_country
			@quoted_place_bounds = @tweet_place_bounds
			@quoted_retweet_count = tweet['retweet_count']
			@quoted_favorite_count = tweet['favorite_count']
			get_hashtags(tweet['entities']['hashtags'])
			@quoted_hastags = @hashtags
			@quoted_mentions = get_mentions(tweet['entities']['user_mentions'])
			@quoted_urls = get_urls(tweet['entities']['urls'])
			@quoted_media = get_media(tweet['entities']['media'])
		else
			@quoted_date = nil
			@quoted_text = nil
			@quoted_reply_id = nil
			@quoted_reply_name = nil
			@quoted_from_id = nil
			@quoted_from_name = nil
			@quoted_from_location = nil
			@quoted_followers = nil
			@quoted_friends = nil
			@quoted_created_at = nil
			@quoted_lang = nil
			@quoted_coordinates = nil
			@quoted_placename = nil
			@quoted_place_country = nil
			@quoted_place_bounds = nil
			@quoted_retweet_count = nil
			@quoted_favorite_count = nil
			@quoted_hastags = nil
			@quoted_mentions = nil
			@quoted_urls = nil
			@quoted_media = nil
		end
	end

	def get_retweet_status(tweet)
		if !tweet.nil?
			@retweeted_date = tweet['created_at']
			@retweeted_text = tweet['text']
			@retweeted_reply_id = tweet['in_reply_to_user_id']
			@retweeted_reply_name = tweet['in_reply_to_screen_name']
			@retweeted_from_id = tweet['user']['id']
			@retweeted_from_name = tweet['user']['name']
			@retweeted_from_location = tweet['user']['location']
			@retweeted_followers = tweet['user']['followers_count']
			@retweeted_friends = tweet['user']['friends_count']
			@retweeted_created_at = tweet['user']['created_at']
			@retweeted_lang = tweet['user']['lang']
			retweeted_coordinates = get_coordinates(tweet['coordinates'])
			@retweeted_coordinates = @tweet_coordinates
			retweeted_place = get_place(tweet['place'])
			@retweeted_placename = @tweet_placename
			@retweeted_place_country = @tweet_place_country
			@retweeted_place_bounds = @tweet_place_bounds
			@retweeted_retweet_count = tweet['retweet_count']
			@retweeted_favorite_count = tweet['favorite_count']
			retweeted_hashtags = tweet['entities']['hashtags']
			get_hashtags(retweeted_hashtags)
			@retweeted_hastags = @hashtags
			@retweeted_mentions = get_mentions(tweet['entities']['user_mentions'])
		else
			@retweeted_date = nil
			@retweeted_text = nil
			@retweeted_reply_id = nil
			@retweeted_reply_name = nil
			@retweeted_from_id = nil
			@retweeted_from_name = nil
			@retweeted_from_location = nil
			@retweeted_followers =nil
			@retweeted_friends = nil
			@retweeted_created_at = nil
			@retweeted_lang = nil
			@retweeted_coordinates = nil
			@retweeted_placename = nil
			@retweeted_place_country = nil
			@retweeted_place_bounds = nil
			@retweeted_retweet_count = nil
			@retweeted_favorite_count = nil
			@retweeted_hastags = nil
			@retweeted_mentions = nil
		end
	end

	def get_hashtags(hashtags)
		if !hashtags.nil?
			hashtags_array = []
			hashtags.each do |ht|
				hashtags_array << ht['text']
			end
			@hashtags = hashtags_array.join(',')
		else
			@hashtags = nil
		end
	end

	def get_mentions(mentions)
		if !mentions.nil?
			mentions_array = []
			mentions.each do |mention|
				mentions_array << mention['name']
			end
			@mentions = mentions_array.join(',')
		else
			@mentions = nil
		end
	end

	def get_media(media)
		if !media.nil?
			media_array = []
			media.each do |medium|
				media_array << medium['media_url']
			end
			@media = media_array.join(',')
		else
			@media = nil
		end
		return @media
	end

		def get_urls(urls)
		if !urls.nil?
			url_array = []
			urls.each do |url|
				url_array << url['expanded_url']
			end
			@urls = url_array.join(',')
		else
			@urls = nil
		end
		return @urls
	end


##Not using method in script

	def get_location(place)
		sleep(1.5)
		location = Geocoder.search(place)
		#puts location.inspect
		if !location.empty?
			location_geometry = location.first.geometry
			location_bounds = location_geometry['bounds']
			if !location_bounds.nil?
				lat_range =  Range.new(location_geometry['location']['lat'], location_geometry['bounds']['northeast']['lat'])
				long_range =  Range.new(location_geometry['location']['lng'], location_geometry['bounds']['northeast']['lng'])
			else
				lat_range =  Range.new(location_geometry['location']['lat'], location_geometry['viewport']['northeast']['lat'])
				long_range =  Range.new(location_geometry['location']['lng'], location_geometry['viewport']['northeast']['lng'])
			end
			if !location.nil?
				@user_location_lat = rand(lat_range).round(7)
				@user_location_long = rand(long_range).round(7)
			else
				@user_location_lat = "here"
				@user_location_long = "here"
			end
		else
			@user_location_lat = "no data"
			@user_location_long = "no data"
		end
	end



end

sfm_files = TweetFilterReader.new
sfm_files.readfiles
