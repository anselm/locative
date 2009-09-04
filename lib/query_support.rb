
require 'dynamapper/geolocate.rb'

############################################################################################
#
# Query parsing and handling
#
# What we do here:
#  1) tear apart ordinary queries and return database results
#  2) package this up outside of the application core for clarity and general consolidation
#  3) let us watch what users are asking for so we can optionally search third party databases
#
# A query may consist of
#   1) a person or persons expressed in the @twitter nomenclature for now
#   2) any number of keywords to restrict the search
#   3) a geographic boundary
#   4) a specific geographic location request
#
# Later I would like to extend this to include
#   5) query time bounds TODO
#   6) query radius TODO
#   7) query longitudinal and latitude wraparound TODO
#
# For example a user can ask a question like "@anselm near pdx" which should yield anselm and friends activity in Portland.
#
############################################################################################

class QuerySupport

	# pull out persons, search terms and tags, location such as "@anselm pizza near portland oregon"
	# TODO should publish the query so everybody can see what everybody is searching for
	def self.query_parse(phrase)
		words = []
		partynames = []
		placenames = []
		terms = phrase.to_s.split.collect { |w| Sanitize.clean(w.downcase) }
		near = false
		terms.each do |w|
			if w[0..0] == "@"
				partynames << w[1..-1]
				next
			end
			if w == "near"
				near = true
				next
			end
			if near
				placenames << w
				next
			end
			words << w
		end

		search = ""
		search << words.join(" ") if words.length > 0

		return { :words => words, :partynames => partynames, :placenames => placenames, :search => search }
	end

	#
	# get query location
	#
	def self.query_locate(q,map_s,map_w,map_n,map_e)

		# TODO deal with time also
		begins = nil
		ends = nil

		# first we have no location
		q[:s] = q[:w] = q[:n] = q[:e] = 0.0

		# look for bounds information in a supplied string using brute force geocoder
		lat,lon,rad = 0.0, 0.0, 0.0
		if q[:placenames].length
			lat,lon,rad = Dynamapper.geolocate(q[:placenames].join(' '))
			rad = 5.0 # TODO hack remove
		end
		if lat < 0.0 || lat > 0.0 || lon < 0.0 || lon > 0.0
			# did we get boundaries from user query as ascii? "pizza near pdx" for example.
			q[:bounds_from_text] = "true"
			q[:s] = lat - rad
			q[:w] = lon - rad
			q[:n] = lat + rad
			q[:e] = lon + rad
		else
			# otherwise try get boundaries from supplied params - this is the more conventional case
			q[:bounds_from_text] = "false"
			if ( map_s < 0.0 || map_s > 0.0 || map_w < 0.0 || map_w > 0.0 || map_n > 0.0 || map_n < 0.0 || map_e < 0.0 || map_e > 0.0 )
				q[:s] = map_s.to_f;
				q[:w] = map_w.to_f;
				q[:n] = map_n.to_f;
				q[:e] = map_e.to_f;
			end
		end
		ActionController::Base.logger.info "query: located the query #{q[:placenames].join(' ')} to #{lat} #{lon} #{rad}"
		return q
	end

	def self.query(question,map_s,map_w,map_n,map_e,synchronous=false)

		# basic string parsing
		q = QuerySupport::query_parse(question)
		QuerySupport::query_locate(q,map_s,map_w,map_n,map_e)

		# look at our internal database and return best results
		results_length = 0
		results = []
		words = q[:words]
		s,w,n,e = q[:s],q[:w],q[:n],q[:e]

		ActionController::Base.logger.info "Query: now looking for: #{words} at location #{s} #{w} #{n} #{e}"

		conditions = []
		condition_arguments = []

		# if there are search terms then add them to the search boundary
		# are we totally cleaning words to disallow garbage? TODO
		if(words.length > 0 )
			conditions << "description @@ to_tsquery(?)"
			condition_arguments << words.join('&')
			conditions << "title @@ to_tsquery(?)"
			condition_arguments << words.join('&')
		end

		# also add lat long constraints
		# TODO deal with wrap around the planet
		if ( s < 0 || s > 0 || w < 0 || w > 0 || n > 0 || n < 0 || e < 0 || e > 0 )
			conditions << "lat >= ? AND lat <= ? AND lon >= ? AND lon <= ?"
			condition_arguments << s;
			condition_arguments << n;
			condition_arguments << w;
			condition_arguments << e;
		end
		
		# always disallow features with 0,0 as a location
		if true
			conditions << " lat <> 0 AND lon <> 0 "
		end

		# filter for posts; we'll collect only people related to those posts later
		if true
			conditions << "(kind = ? OR kind = ? OR kind = ?)"
			condition_arguments << Note::KIND_POST
			condition_arguments << Note::KIND_PLACE
			condition_arguments << Note::KIND_MAP
		end

		#
		# collect a big old pile of posts
		#
		results_length = 0
		results = []

ActionController::Base.logger.info "ABOUT TO QUERY #{conditions} and #{condition_arguments.join(' *** ' ) } "

		conditions = [ conditions.join(' AND ') ] + condition_arguments

		Note.all(:conditions => conditions , :limit => 255, :order => "id desc" ).each do |note|
			results << note
			results_length = results_length + 1
		end

ActionController::Base.logger.info "GOT #{results_length} posts "

		#
		# lets go ahead and inject in only the people who were associated with the posts we found (so the user can see them)
		# TODO this could be cleaned up massively using a bit of smarter SQL that finds uniques only or at least a HASH join
		#

		people = {}
		results.each do |post|
			person = Note.find(:first,:conditions => { :id => post.owner_id } )
			people[post.owner_id] = person if person != nil
		end
		people.each do |key,value|
			results << value
			results_length = results_length + 1
		end

		ActionController::Base.logger.info "Query: got results #{results} #{results_length}"

		q[:results_length] = results_length
		q[:results] = results

		return q
	end

end
