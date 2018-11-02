require 'rubygems'
require 'csv'
require 'geocoder'
require 'openssl'
require 'date'
require 'sanitize'

class TwitterGeolocator

	def initiate
		Geocoder.configure(lookup: :google, api_key: 'ADD_GOOGLE_KEY', use_https: true, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
		create_csv
	end	

	def create_csv
			#tweets_file = "#{ARGV.last}_geolocated.csv"
			output_file = ARGV.last
			CSV.open(output_file, 'ab') do |csv|
				begin
					new_file = CSV.read(output_file,:encoding => "iso-8859-1",:col_sep => ",")
				  	if new_file.none?
				    	csv << ["id", "tweet_url", "created_at", "parsed_created_at", "user_screen_name", "shared_media_type", "theme", "location", "location_coordinates", "location_latitute", "location_longitude", "steet_level_info", "text", "tweet_type", "coordinates", "hashtags", "media", "urls", "favorite_count", "in_reply_to_screen_name", "in_reply_to_status_id", "in_reply_to_user_id", "lang", "place", "possibly_sensitive", "retweet_count", "retweet_or_quote_id", "retweet_or_quote_screen_name", "retweet_or_quote_user_id", "source", "user_id", "user_created_at", "user_default_profile_image", "user_description", "user_favourites_count", "user_followers_count", "user_friends_count", "user_listed_count", "user_location", "user_name", "user_statuses_count", "user_time_zone", "user_urls", "user_verified"]
				  	end
					CSV.foreach(ARGV.first, headers:true) do |tweet|
						begin
							puts tweet['location']
							puts tweet['street_level_info']
							csv << [tweet['id'], tweet['tweet_url'], change_dateformat(tweet['created_at']), change_dateformat(tweet['parsed_created_at']), tweet['user_screen_name'], tweet['shared_media_type'], tweet['theme'], tweet['location'], get_location(tweet['location']), @lat, @long, tweet['street_level_info'], tweet['text'], tweet['tweet_type'], tweet['coordinates'], tweet['hashtags'], tweet['media'], tweet['urls'], tweet['favorite_count'], tweet['in_reply_to_screen_name'], tweet['in_reply_to_status_id'], tweet['in_reply_to_user_id'], tweet['lang'], get_location(tweet['place']), tweet['possibly_sensitive'], tweet['retweet_count'], tweet['retweet_or_quote_id'], tweet['retweet_or_quote_screen_name'], tweet['retweet_or_quote_user_id'], Sanitize.fragment(tweet['source']), tweet['user_id'], tweet['user_created_at'], tweet['user_default_profile_image'], tweet['user_description'], tweet['user_favourites_count'], tweet['user_followers_count'], tweet['user_friends_count'], tweet['user_listed_count'], tweet['user_location'], tweet['user_name'], tweet['user_statuses_count'], tweet['urls'], tweet['user_time_zone'], tweet['user_urls'], tweet['user_verified']]
						rescue Exception => e
	  						puts "Error #{e}"
	  						next	
						end	
					end	
				rescue Exception => e
		  			puts "Error #{e}"
		  			next
		  		end	
	  		end
		end

		def change_dateformat(date)
			d = DateTime.parse(date)
			#new_date = d.strftime("%d/%m/%Y %T") ###for Tableau Desktop
			new_date = d.strftime("%m/%d/%Y %T") ###for Tableau Public
			return new_date
		end	


		def get_location(place)
			if !place.nil?
				sleep(1.5)
				location = Geocoder.search(place)
				#puts location.inspect
				if !location.empty?
					#for Google Geocoding API
					@lat = location.first.geometry['location']['lat']
					@long = location.first.geometry['location']['lng'] 
					@coordinates = location.first.geometry['location']
					#for nominatum Geocoding API
					#@long = location.first.coordinates[1]
					#@lat = location.first.coordinates[0]
					#@coordinates = location.first.coordinates
				else
					@coordinates = nil	
					@lat = nil
					@long = nil
				end
			else	
				@coordinates = nil
				@lat = nil
				@long = nil
			end
			return @coordinates	
		end	


end

geolocated_tweets = TwitterGeolocator.new
geolocated_tweets.initiate

