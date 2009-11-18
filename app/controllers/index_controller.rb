require 'net/http'
require 'uri'
require 'open-uri'
require 'lib/query_support.rb'
require 'note.rb'

class IndexController < ApplicationController

  #
  # The client side is javascript so this does very litle
  # Does remember the map location
  #
  def index
    @map.question = nil
    @map.question = session[:q] = params[:q] if params[:q]
    @map.question = session[:q] if !params[:q]
    @map.south = @map.west = @map.north = @map.east = 0.0
    begin
	# attempt to fetch map location from parameters
	@map.south    = session[:s] = params[:s].to_f if params[:s]
	@map.west     = session[:w] = params[:w].to_f if params[:w]
	@map.north    = session[:n] = params[:n].to_f if params[:n]
	@map.east     = session[:e] = params[:e].to_f if params[:e]
	# otherwise fetch them from session state if present (or set to nil)
	@map.south    = session[:s].to_f if !params[:s]
	@map.west     = session[:w].to_f if !params[:w]
	@map.north    = session[:n].to_f if !params[:n]
	@map.east     = session[:e].to_f if !params[:e]
    rescue
    end
  end

  #
  # Our first pass at an API - handle place, person and subject queries
  #
  def json

    # debugging to test a twitter gateway - not used for locative - see github.com/anselm/angel
    synchronous = false
    synchronous = true if params[:synchronous] && params[:synchronous] ==true

    # pull user question and location of question; ignore session state
    @q = nil
    @q = session[:q] = params[:q].to_s if params[:q]
    @s = @w = @n = @e = 0.0
    begin
      @s = session[:s] = params[:s].to_f if params[:s]
      @w = session[:w] = params[:w].to_f if params[:w]
      @n = session[:n] = params[:n].to_f if params[:n]
      @e = session[:e] = params[:e].to_f if params[:e]
    rescue
    end

    # for the nov 18 2009 ardemo for dorkbot i need to return points near user so accept a radius and location
    @rad = nil
    @lon = 0
    @lat = 0
    begin
      @rad = params[:rad].to_f if params[:rad]
      @lon = params[:lon].to_f if params[:lon]
      @lat = params[:lat].to_f if params[:lat]
      if @rad != nil && @rad > 0.0
        @s = @lat - @rad
        @n = @lat + @rad
        @w = @lon - @rad
        @e = @lon + @rad
      end
    end 

    # for the nov 18 ardemo for dorkbot i need a quick hack to make posts; this will do
    # TODO must block bad actors later
    # TODO should accept a key and deal with dupes so client can have a deferred offline mode
    if params[:title]
      @user = User.first
      @userid = @user.id || 0
      @note = Note.new( { :kind => "KIND_PLACE", :title => params[:title], :owner_id => @userid, :lat => @lat, :lon => @lon, :rad => @rad } )
      if @note.save
        render :json => @note.to_json, :layout => nil
      else
        render :text => "fail", :layout => nil
      end
      return
    end

    # a hack: we don't deal with datelines very well TODO improve
    # temporary solution is that if we are on the west side then extend west, else extend east
    if @w > @e
      if @w > 0
        @w = @w - 360
      else
        @e = @e + 360
      end
    end

    # perform search
    results = QuerySupport::query(@q,@s,@w,@n,@e,synchronous)

    # for the nov 18 ardemo for dorkbot i need to distance sort the points and cull them so i don't crash the iphone
    # abuse the radius field for this
    if @rad != nil && @rad > 0.0
      r = results[:results]
      r.each { |note| note.rad = (@lat-note.lat)*(@lat-note.lat)+(@lon-note.lon)*(@lon-note.lon) }
      r.sort! { |a,b| a.rad <=> b.rad }
      r = r[0...49]
      r.each { |note| ActionController::Base.logger.info "*** looking at #{note.title} at #{note.lat} and #{note.lon} and #{note.rad}" }
      results[:results] = r
    end

    render :json => results.to_json
  end

  def about
    render :layout => 'static'
  end

  #
  # below is a test for flash globe - merge in above or throw away TODO
  #
  def test
    # we'll return a selection of recent posts that can be used to update the globe 
    @notes = Note.find(:all, :limit => 50, :order => "updated_at DESC", :conditions => { :kind => 'post' } );
    # from those posts I'd like to also return the related users
    @users = []
    @notes.each do |note|
      user = Note.find(:first,:conditions => { :id => note.owner_id, :kind => 'user' } )
      if user
        @users << user
      end
    end
    # from those users I'd like to also add a set of related users so we can map worldwide relationships
	#    @users.each do |user|
	#       party.relation_add(Note::RELATION_FRIEND,1,party2.id)  
	# end
    @notes = Note.find(:all, :limit => 50, :order => "updated_at DESC" );
    render :layout => false
  end

end
