class CreateNotes < ActiveRecord::Migration

  def self.up

    #
    # Core of our basic subject matter definition
    # See relations for extended metadata (below)
    #
    create_table :notes do |t|

      t.string   :type             # for subclassing notes for rails; not used at application level
      t.string   :kind             # for subclassing notes for application level; effectively a kind of mime type
      t.string   :uuid             # each object has a uuid
      t.string   :provenance       # the server or unique identifier that this note came from such as twitter, or foursquare

      t.integer  :permissions      # private, protected public
      t.integer  :statebits        # other state bits
      t.integer  :owner_id         # foreign key for local party that made this
      t.integer  :related_id       # a relationship of child parent such as a reply in a tree of messages

      t.string   :title            # the title of the subject in question, often used for display
      t.string   :link             # the link to more data about the subject - only one formal link per subject
      t.text     :description      # the description - extended brief description
      t.string   :depiction        # the depiction - a single image - actually we may use a different approach with a rails gem
      t.string   :location         # a single location - for now this is an english string - later i would like polygons 
      t.string	 :tagstring        # an english string that collects the tags
      t.float    :lat              # a point latitude, longitude and radius - later i would like polygons
      t.float    :lon
      t.float    :rad
      t.integer  :depth            # zoom depth hint for map view
      t.integer  :score            # an objective score
      t.datetime :begins           # temporal beginning and end
      t.datetime :ends

      t.timestamps                 # record creation and update
    end

    #
    # Notes can contain arbitrary meta-data in an RDF like manner.
    # Tags and many other relations are kept here; we don't do a lot of database level structure - the application builds many relation types at a higher level.
    #
    # One consideration:
    # If two notes contain the same meta-data that data is not conserved; it exists in duplicate for each node.  A tag 'blue' is separate for each node tagged as such.
    # This may make it slightly harder to find if two notes share the same attribute...
    #
    create_table :relations do |t|
      t.string   :type
      t.string   :kind
      t.text     :value
      t.integer  :note_id
      t.integer  :sibling_id
      t.timestamps
    end

  end

  def self.down
    drop_table   :notes
    drop_table   :relations
  end

end

