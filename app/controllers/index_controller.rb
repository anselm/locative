require 'net/http'
require 'uri'
require 'open-uri'
require 'lib/query_support.rb'
require 'note.rb'
require 'world_boundaries.rb'

class IndexController < ApplicationController

  #
  # Web UI
  #
  def index

	# configure map engine
	# this is javascript but i'd like to have it be purely static TODO improve
	parse_arguments
    @map.question = @q
	@map.south = @s
	@map.west = @w
	@map.north = @n
	@map.east = @e
	@map.countrycode = @country

  end

  #
  # API
  #
  # accepts a query string and geographic boundaries
  #
  def json

    # pull arguments from parameters
    parse_arguments

    # perform search
    results = QuerySupport::query(@q,@s,@w,@n,@e,@synchronous)

	# temporary code - distance sort and limit the results
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

  #
  # Parse arguments
  #
  def parse_arguments

    # a flag to mark that we'd like to avoid doing heavy remote api calls such as to twitter
    @synchronous = false
    @synchronous = true if params[:synchronous] && params[:synchronous] == true

	# accept a query phrase including persons, places and terms
    @q = nil
    @q = session[:q] = params[:q].to_s if params[:q]
	@q = session[:q] if !params[:q]

    # accept an explicit boundary { aside from any locations specified in the query }
    @s = @w = @n = @e = 0.0
    begin
		@s = session[:s] = params[:s].to_f if params[:s]
		@w = session[:w] = params[:w].to_f if params[:w]
		@n = session[:n] = params[:n].to_f if params[:n]
		@e = session[:e] = params[:e].to_f if params[:e]
		@s = session[:s].to_f if !params[:s]
		@w = session[:w].to_f if !params[:w]
		@n = session[:n].to_f if !params[:n]
		@e = session[:e].to_f if !params[:e]
    rescue
    end

    # accept an explicit country code - this will override the location boundary supplied above
	# TODO arguably we should compute the country code boundary right now so that radius can be used
    @country = nil
    @country = params[:country] if params[:country] && params[:country].length > 1

    # optionally accept a radius query to constrain the results
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

	# Allow a new post. TODO this needs to block bad actors and also deal with duplicates.
    if params[:title]
      @user = User.first
      @userid = @user.id || 0
      @note = Note.new( {	:kind => "KIND_PLACE",
							:title => params[:title],
							:owner_id => @userid,
							:lat => @lat,
							:lon => @lon,
							:rad => @rad
						} )
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

  end


end
