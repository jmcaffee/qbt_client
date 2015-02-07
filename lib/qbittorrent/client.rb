##############################################################################
# File::    client.rb
# Purpose:: Web UI client for qBittorrent.
#
# Author::    Jeff McAffee 2015-02-07
# Copyright:: Copyright (c) 2015, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require 'json/pure'
require 'httparty'
#require 'nokogiri'

#require_relative 'torrent_data'
#require_relative 'rss_torrent_data'


module Qbittorrent

  class Client
    include HTTParty

    attr_accessor :result
    attr_reader   :response
    attr_reader   :torrents
    attr_reader   :rssfeeds
    attr_reader   :rssfilters
    attr_reader   :settings

    ###
    # Processor constructor
    #
    def initialize(ip, port, user, pass)
      @ip         = ip
      @port       = port
      @user       = user
      @pass       = pass
      @base_url   = "/gui/?"
      @url        = ""
      @result     = nil
      @http       = nil
      @token      = nil
      @settings   = Array.new
      @torrentc   = nil

      @torrents         = Hash.new
      @torrents_removed = Hash.new
      @rssfeeds         = Hash.new
      @rssfilters       = Hash.new
    end

    ###
    #
    #
    def user
      @user
    end

    ###
    #
    #
    def pass
      @pass
    end

    def uri
      "#{@ip}:#{@port}/command"
    end

    ###
    # Connect to app
    #
    def connect
      self.class.digest_auth(user, pass) #, {
      #  'realm' => '',
      #  'nonce' => 'nonce',
      #  'opaque' => 'opaque',
      #})

      response = self.class.get(uri)
      self.class.digest_auth(user, pass)
      response = self.class.get(uri)
    end

    ###
    # Send a GET query
    #
    # query:: Query to send
    #
    def send_get_query(query)
      data = nil
      start_session()
      get_token()
      data = get_query("#{query}&token=#{@token}")
      stop_session()

      return data
    end

    ###
    # Get uTorrent settings
    #
    def get_utorrent_settings()
      @url = "/gui/?action=getsettings"

      send_get_query(@url)
      result = parse_response()

      @settings = result["settings"]
    end

    ###
    # Get a torrent's job properties
    #
    def get_torrent_job_properties(hash)
      @url = "/gui/?action=getprops&hash=#{hash}"

      send_get_query(@url)
      result = parse_response()
    end

    ###
    # Set torrent job properties
    #
    # props: hash of hashes
    #   Expected format:
    #     {hash1 => {'prop1' => 'value1', 'prop2' => 'value2'},
    #      hash2 => {'prp1' => 'val1', 'prp2' => 'val2'}}
    def set_job_properties(props)
      urlRoot = "/gui/?action=setprops"
      jobprops = ""

      props.each do |hash, propset|
        jobprops = "&hash=#{hash}"
        propset.each do |property, value|
          jobprops += "&s=#{property}&v=#{value}"
        end
      end

      raise "Invalid job properties provided to UTorrentWebUI:set_job_properties: #{props.inspect}" if jobprops.empty?
      @url = urlRoot + jobprops
      send_get_query(@url)
      result = parse_response()
    end

    ###
    # Send uTorrent request to remove torrent
    #
    def remove_torrent(hash)
      @url = "/gui/?action=removedata&hash=#{hash}"

      send_get_query(@url)
      result = parse_response()
    end

    ###
    # Get a list of Torrents
    #
    def get_torrent_list(cache_id = nil)
      @url = "/gui/?list=1"
      @url = "/gui/?list=1&cache=#{cache_id}" if !cache_id.nil?

      send_get_query(@url)
      result = parse_response()

      return parse_list_request_response( result )
    end

    ###
    # Get a list of Torrents using a cache value
    #
    def get_torrent_list_using_cache(cache_id)
      # TODO: Remove this method
      @url = "/gui/?list=1&cache=#{cache_id}"

      send_get_query(@url)
      result = parse_response()

      return parse_list_request_response( result )
    end

    ###
    # Indicates if there are torrents that have been removed.
    #
    # returns:: none
    #
    def torrents_removed?()
      return false if (@removed_torrents.nil? || @removed_torrents.length == 0)
      return true
    end

    ###
    # Return the cache token
    #
    def cache()
      return @torrentc
    end

  private

    ###
    # Start a HTTP session
    #
    # returns:: HTTP object
    #
    def start_session()
      @http = Net::HTTP.start(@ip, @port)
      @http.read_timeout = 500 # seconds
    end

    ###
    # Stop a HTTP session
    #
    def stop_session()
      @http.finish
    end

    ###
    # Send a GET query
    #
    # returns:: response body
    #
    def get_query(query)
      req = Net::HTTP::Get.new(query)
      req.basic_auth @user, @pass
      req["cookie"] = @cookie if @cookie

      if @verbose
        # FIXME: Replace 'puts' with 'log'
        puts "  REQUEST HEADERS:"
        req.each_header do |k,v|
          puts "    #{k}  =>  #{v}"
        end
        puts
      end # if @verbose

      @response = @http.request(req)

      if @verbose
        puts "  RESPONSE HEADERS:"
        @response.each_header do |k,v|
          puts "    #{k}  =>  #{v}"
        end
        puts
      end # if @verbose

      data = @response.body
      raise "Invalid response. Check the address, login and password of the server." if data.nil? || data.empty?

      data
    end

    ###
    # Get the uTorrent token for queries
    #
    # returns:: token
    def get_token()
      get_query("/gui/token.html")
      data = Nokogiri::HTML(@response.body)

      @token = data.at("div#token").inner_html

      store_cookie()
      @token
    end

    ###
    # Store the cookie if sent
    #
    def store_cookie()
      tmpcookie = @response["set-cookie"]
      @cookie = tmpcookie.split(";")[0] if !tmpcookie.nil?
    end

    ###
    # Parse a response result from a torrent list request
    #
    # response:: the JSON parsed reponse
    #
    def parse_list_request_response(response)
      # Clear out the torrents hash
      @torrents.clear unless @torrents.nil?

      # Clear out the removed torrents hash
      @torrents_removed.clear unless @torrents_removed.nil?

      # Clear out the RSS Feeds hash
      @rssfeeds.clear unless @rssfeeds.nil?

      # Clear out the RSS Filters hash
      @rssfilters.clear unless @rssfilters.nil?

      # Stash the cache
      @torrentc = response["torrentc"]

      parse_torrent_list_reponse( response )      if response.include?("torrents")
      parse_torrent_list_cache_response( response ) if response.include?("torrentsp")
      log("  List Request Response does not contain either 'torrents' or 'torrentsp'") if (verbose && !response.include?("torrents") && !response.include?("torrentsp"))

      parse_rss_feeds_list_response( response )     if response.include?("rssfeeds")
      log("  List Request Response does not contain RSS Feed data") if (verbose && !response.include?("rssfeeds"))

      parse_rss_filters_list_response( response )   if response.include?("rssfilters")
      log("  List Request Response does not contain RSS Filter data") if (verbose && !response.include?("rssfilters"))

      return response
    end

    ###
    # Parse a response result from a torrent list request
    #
    # response:: the JSON parsed reponse
    #
    def parse_torrent_list_reponse(response)
      torrents = response["torrents"]

      # torrents is an array of arrays
      torrents.each do |t|
        td = TorrentData.new(t)
        @torrents[td.hash] = td
      end
    end

    ###
    # Parse a response result from a torrent list cache request
    #
    # response:: the JSON parsed reponse
    #
    def parse_torrent_list_cache_response(response)
      torrents = response["torrentsp"]

      # torrents is an array of arrays
      torrents.each do |t|
        td = TorrentData.new(t)
        @torrents[td.hash] = td
      end

      # Store the 'removed' torrents
      removed = response["torrentsm"]
      removed.each do |t|
        td = TorrentData.new(t)
        @torrents_removed[td.hash] = td
      end
    end

    ###
    # Parse a rssfeed response result from a torrent list request
    #
    # response:: the JSON parsed reponse
    #
    def parse_rss_feeds_list_response(response)
      feeds = response["rssfeeds"]

      # feeds is an array of arrays
      feeds.each do |f|
        feed = RSSFeed.new(f)
        @rssfeeds[feed.feed_name] = feed
      end
    end

    ###
    # Parse a rssfilter response result from a torrent list request
    #
    # response:: the JSON parsed reponse
    #
    def parse_rss_filters_list_response(response)
      filters = response["rssfilters"]

      # filters is an array of arrays
      filters.each do |f|
        filter = RSSFilter.new(f)
        @rssfilters[filter.feed_name] = filter
      end
    end

    ###
    # Parse the response data (using JSON)
    #
    def parse_response
      if @response.nil? || !@response
        #$LOG.debug "Response is NIL or empty."
        return
      end

      result = JSON.parse(@response.body)
    end
  end
end

