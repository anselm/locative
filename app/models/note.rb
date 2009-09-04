require 'stemmer'  
require 'hpricot'  
require 'httpclient'
require 'json'
#require 'solr'
#require 'enumerated_attribute' does not work with activerecord

###########################################################################################################
#
# unique edges on nodes used to form tagging and relationships
# stores name, value, provenance
# is unique per node so two different nodes would have the same tag 'purple' independently
# ie you have to do 'select note_id from relations where kind = 'tag' && value == 'purple' ...
#
###########################################################################################################

class Relation < ActiveRecord::Base
  belongs_to :note
  #  acts_as_solr( :fields => [ :value ] )  ...disabled for now...
end

###########################################################################################################
#
# A base class used everywhere that allows relationships
#
###########################################################################################################

class Note < ActiveRecord::Base

  has_many :relations

  # acts_as_solr :fields => [:title, {:lat=>:range_float}, {:lon=>:range_float}] # slower than heck - using tsearch instead
  acts_as_tsearch :fields => ["title","description"]

  #
  # The database architecture consists of nodes and edges
  #
  # Edges may relate two nodes
  # Edges may just be about one node
  # Edges may be labelled
  #
  # There is a ongoing design question regarding if some attributes should be first class nodes or just edges
  # RELATION_URL is being treated as both an edge and as a first class node for example.
  #

=begin
  RELATIONS = %w{
					RELATION_TAG			# a tag or hashtag
					RELATION_CATEGORY		# a formal category object similar to a tag but from a named set
					RELATION_ENTITY			# a citation of an entity [ also see first class entities in notes ]
					RELATION_RELATION		# an unlabelled relation between two notes
					RELATION_FRIEND			# a friendship relation between two notes
					RELATION_URL			# a citation of an url [ see also first class treatment of urls ]
					RELATION_IMAGE			# a citation of an image
					RELATION_AUDIO			# a citation of an audio
					RELATION_MOVIE			# a citation of a movie
				}

  KINDS = %w{
					KIND_USER			# a stand in for a local user account - a user makes posts
					KIND_FEED			# a feed - a feed makes posts
					KIND_REPORTER			# a reporter person - makes posts
					KIND_REPORT			# a kind of post (unused)
					KIND_POST			# a user post
					KIND_GROUP			# a grouping of posts
					KIND_EVENT			# an event that groups posts
					KIND_PLACE			# a place that groups posts
					KIND_MAP			# a map that groups posts
					KIND_FILTER			# a filter that groups posts
					KIND_ENTITY			# an entity of some kind
					KIND_URL			# a treatment of an url edge as a first class object [ used for client views ]
					KIND_TAG			# a treatment of an edge as a first class object [ just an idea ]
				}
=end

  RELATIONS = %w{
					RELATION_TAG		
					RELATION_CATEGORY
					RELATION_ENTITY	
					RELATION_RELATION
					RELATION_FRIEND		
					RELATION_URL	
					RELATION_IMAGE
					RELATION_AUDIO
					RELATION_MOVIE
				}

  KINDS = %w{
					KIND_USER	
					KIND_FEED
					KIND_REPORTER
					KIND_REPORT
					KIND_POST	
					KIND_GROUP
					KIND_EVENT
					KIND_PLACE
					KIND_MAP	
					KIND_FILTER	
					KIND_ENTITY	
					KIND_URL
					KIND_TAG
				}

  STATEBITS_RESERVED = 0
  STATEBITS_RESPONDED = 1
  STATEBITS_UNRESPONDED = 2
  STATEBITS_FRIENDED = 4
  STATEBITS_DIRTY = 8
  STATEBITS_GEOLOCATED = 16 

  RELATIONS.each { |k| const_set(k,k) }
  KINDS.each { |k| const_set(k,k) }

  # enum_attr :METADATA, RELATIONS, :nil => true  # fails with activerecord
  # enum_attr :KIND, KINDS, :nil => true # fails with activerecord

  # Paperclip
  has_attached_file :photo,
    :styles => {
      :thumb=> "100x100#",
      :small => "150x150>"
    }
 
end
 


###########################################################################################################
#
# Note Relations Management
# Notes have support for arbitrary relationships attached to any given note
# A typing system is implemented at this level; above the scope of activerecord
# The reasoning for this is to have everything in the same sql query space
#
###########################################################################################################

class Note

  def relation_value(kind, sibling_id = nil)
    r = nil
    if sibling_id
	  r = Relation.find(:first, :conditions => { :note_id => self.id, :kind => kind, :sibling_id => sibling_id} )
    else
	  r = Relation.find(:first, :conditions => { :note_id => self.id, :kind => kind } )
    end
    return r.value if r
    return nil
  end

  def relation_first(kind, sibling_id = nil)
    r = nil
    if sibling_id
	  r = Relation.find(:first, :conditions => { :note_id => self.id, :kind => kind, :sibling_id => sibling_id} )
    else
	  r = Relation.find(:first, :conditions => { :note_id => self.id, :kind => kind } )
    end
    return r
  end

  def relation_first_exact(kind, value, sibling_id = nil)
    r = nil
    if sibling_id
	  r = Relation.find(:first, :conditions => { :note_id => self.id, :kind => kind, :value => value, :sibling_id => sibling_id} )
    else
	  r = Relation.find(:first, :conditions => { :note_id => self.id, :kind => kind, :value => value } )
    end
    return r
  end

  def relations_all(kind = nil, sibling_id = nil)
    query = { :note_id => self.id }
    query[:kind] = kind if kind
    query[:sibling_id] = sibling_id if sibling_id
    return Relation.find(:all,:conditions=>query)
  end

  # TODO rate limit
  # TODO use a join
  def relation_as_notes(kind = nil, sibling_id = nil)
    query = { :note_id => self.id }
    query[:kind] = kind if kind
    query[:sibling_id] = sibling_id if sibling_id
    relations = Relation.find(:all,:conditions=>query)
	results = []
	relations.each do |r|
		note = Note.find(:first,:conditions => { :id => r.sibling_id } )
		results << note if note
	end
	return results
  end

  #
  # destroy all the relations on something of a kind
  #
  def relation_destroy(kind = nil, sibling_id = nil)
    query = { :note_id => self.id }
    query[:kind] = kind if kind
    query[:sibling_id] = sibling_id if sibling_id
    Relation.destroy_all(query)
  end

  #
  # add each relation uniquely only - meaning that if the kind and value exist then do not add it again
  # also note we always store as strings and we always remove head and tail whitespace
  #
  def relation_add(kind, value, sibling_id = nil)
    return if !value || value == nil
    value = value.to_s.strip
    relation = relation_first_exact(kind,value,sibling_id)
    if relation
	# relation.update_attributes(:value => value, :sibling_id => sibling_id )
	return
    end
    Relation.create!({
                 :note_id => self.id,
                 :sibling_id => sibling_id,
                 :kind => kind,
                 :value => value
               })
  end

  #
  # obliterate the previous kind of relation set and add the new set.
  # for example erase all tags on something and then set new tags
  #
  def relation_add_array(kind,value,sibling_id = nil)
    relation_destroy(kind,sibling_id)
    return if !value || value == nil || value.length == 0
    value.each do |v|
      Relation.create!({
                   :note_id => self.id,
                   :sibling_id => sibling_id,
                   :kind => kind,
                   :value => v.strip
                 })
    end
  end

  #
  # a helper to specifically deal with the ever so common hash tag pattern
  #
  def relation_save_hash_tags(text)
     return if !text || text == nil || text.length = 0
     text.scan(/#[a-zA-Z]+/i).each do |tag|
       relation_add(Note::RELATION_TAG,tag[1..-1])
     end
  end

end

=begin

###########################################################################################################
#
# here is a test of carrot2 to cluster
# since carrot2 only clusters well for 1k documents or so we will need to reduce our query scope before here
#
###########################################################################################################

class Note

  def dcs_dump(jsonResponse)
    # puts jsonResponse
    response = JSON.parse(jsonResponse)
    descriptions = response['clusters'].map do
      |cluster| "%s [%i document(s)]" % [cluster['phrases'].join(", "), cluster['documents'].length]
    end
    puts descriptions.join("\n")
  end

  def dcs_request(uri, data)
    boundary = Array::new(16) { "%2.2d" % rand(99) }.join()
    extheader = { "content-type" => "multipart/form-data; boundary=___#{ boundary }___" }
    client = HTTPClient.new
    return client.post_content(uri, data, extheader)
  end

  def dcs_import
    uri = "http://localhost:8080/dcs/rest"
    mydata = open("mydata.xml");
    results = dcs_request(uri, {
      # "dcs.source" => "boss-web",  # examine sources TODO
      "dcs.c2stream" => mydata,
      "query" => "data mining",
      "dcs.output.format" => "JSON",
      "dcs.clusters.only" => "false" # examine TODO 
    })
    dump results
  end

end


=end
