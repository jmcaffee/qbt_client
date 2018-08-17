##############################################################################
# File::    web_ui.rb
# Purpose:: Web UI client for qBittorrent.
#
# Author::    Jeff McAffee 2015-02-07
# Copyright:: Copyright (c) 2015, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require 'multi_json'
require 'httparty'
require 'digest'


module QbtClient

  class WebUI
    include HTTParty

    if ENV["DEBUG"]
      debug_output $stdout
    end

    ###
    # constructor
    #
    def initialize(ip, port, user, pass)
      @ip         = ip
      @port       = port
      @user       = user
      @pass       = pass
      @sid        = nil

      #self.class.digest_auth(user, pass)
      host = "#{ip}:#{port}"
      self.class.base_uri host
      self.class.headers "Referer" => "http://#{host}"
      authenticate
      self.class.cookies.add_cookies(@sid)
    end


    ###
    # Authenticate with the server
    #
    # Login with username and password.
    # Store returned SID cookie value used as auth token for later calls.
    #
    def authenticate
      options = {
        body: "username=#{@user}&password=#{@pass}"
      }

      # Have to clear out the cookies or the old SID gets sent while requesting
      # the new SID (and it fails).
      self.class.cookies.clear

      res = self.class.post('/login', options)
      if res.success?
        token = res.headers["Set-Cookie"]
        raise QbtClientError.new("Login failed: no SID (cookie) returned") if token.nil?

        token = token.split(";")[0]
        @sid = token
      else
        raise QbtClientError.new(res)
      end
    end

    ###
    # Get the application's API version
    #
    # Returns an integer
    #
    def api_version
      self.class.format :json
      self.class.get('/version/api').parsed_response
    end

    ###
    # Get the application's minimum API version
    #
    # Returns an integer
    #
    def api_min_version
      self.class.format :json
      self.class.get('/version/api_min').parsed_response
    end

    ###
    # Get the application's version
    #
    # Returns an integer
    #
    def qbittorrent_version
      self.class.format :plain
      self.class.get('/version/qbittorrent').parsed_response
      #self.class.get('/version/qbittorrent')
    end

    ###
    # Get array of all torrents
    #
    # Example response:
    #    [
    #      {
    #          "dlspeed"=>"3.1 MiB/s",
    #          "eta"=>"9m",
    #          "hash"=>"156b69b8643bd11849a5d8f2122e13fbb61bd041",
    #          "name"=>"slackware64-14.1-iso",
    #          "num_leechs"=>"1 (14)",
    #          "num_seeds"=>"97 (270)",
    #          "priority"=>"*",
    #          "progress"=>0.172291,
    #          "ratio"=>"0.0",
    #          "size"=>"2.2 GiB",
    #          "state"=>"downloading",
    #          "upspeed"=>"0 B/s"
    #      },
    #      {
    #        "dlspeed"=>"1.8 KiB/s",
    #        "eta"=>"28d 1h",
    #        "hash"=>"1fe5775d32d3e58e48b3a96dd2883c5250882cda",
    #        "name"=>"Grimm.S04E12.720p.HDTV.X264-DIMENSION.mkv",
    #        "num_leechs"=>"7 (471)",
    #        "num_seeds"=>"15 (1866)",
    #        "priority"=>"*",
    #        "progress"=>1.53669e-07,
    #        "ratio"=>"0.0",
    #        "size"=>"825.4 MiB",
    #        "state"=>"downloading",
    #        "upspeed"=>"0 B/s"
    #      }
    #    ]
    #
    def torrent_list
      self.class.format :json
      self.class.get('/query/torrents').parsed_response
    end

    # Polls the client for incremental changes.
    #
    # @param interval Update interval in seconds.
    #
    # @yield [Hash] the return result of #sync.
    def poll interval: 10, &block
      raise '#poll requires a block' unless block_given?

      response_id = 0

      loop do
        res = self.sync response_id

        if res
          response_id = res['rid']
          
          yield res
        end

        sleep interval
      end
    end

    # Requests partial data from the client.
    #
    # @param response_id [Integer] Response ID. Used to keep track of what has
    #   already been sent by qBittorrent.
    #
    # @return [Hash, nil] parsed json data on success, nil otherwise
    #
    # @note Read more about `response_id` at https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-Documentation#get-partial-data
    def sync response_id = 0
      req = self.class.get '/sync/maindata', format: :json,
                           query: { rid: response_id }
      res = req.parsed_response

      if req.success?
        return res
      end
    end

    def torrent_data torrent_hash
      torrents = torrent_list

      torrents.each do |t|
        if t["hash"] == torrent_hash
          return t
        end
      end
    end

    ###
    # Get properties of a torrent (different data than what's returned
    # in #torrent_list).
    #
    # Example response:
    #    {
    #      "comment"=>"Visit us: https://eztv.ch/ - Bitcoin: 1EZTVaGQ6UsjYJ9fwqGnd45oZ6HGT7WKZd",
    #      "creation_date"=>"Friday, February 6, 2015 8:01:22 PM MST",
    #      "dl_limit"=>"∞",
    #      "nb_connections"=>"0 (100 max)",
    #      "piece_size"=>"512.0 KiB",
    #      "save_path"=>"/home/jeff/Downloads/",
    #      "share_ratio"=>"0.0",
    #      "time_elapsed"=>"< 1m",
    #      "total_downloaded"=>"646.8 KiB (657.8 KiB this session)",
    #      "total_uploaded"=>"0 B (0 B this session)",
    #      "total_wasted"=>"428 B",
    #      "up_limit"=>"∞"
    #    }
    #
    def properties torrent_hash
      self.class.format :json
      self.class.get('/query/propertiesGeneral/' + torrent_hash).parsed_response
    end

    ###
    # Get tracker data for a torrent
    #
    # Example response:
    #    [
    #      {
    #        "msg"=>"",
    #        "num_peers"=>"0",
    #        "status"=>"Working",
    #        "url"=>"udp://open.demonii.com:1337"},
    #      {
    #        "msg"=>"",
    #        "num_peers"=>"0",
    #        "status"=>"Not contacted yet",
    #        "url"=>"udp://tracker.coppersurfer.tk:6969"},
    #      {
    #        "msg"=>"",
    #        "num_peers"=>"0",
    #        "status"=>"Not contacted yet",
    #        "url"=>"udp://tracker.leechers-paradise.org:6969"},
    #      {
    #        "msg"=>"",
    #        "num_peers"=>"0",
    #        "status"=>"Not contacted yet",
    #        "url"=>"udp://exodus.desync.com:6969"}
    #    ]
    #
    def trackers torrent_hash
      self.class.format :json
      self.class.get('/query/propertiesTrackers/' + torrent_hash).parsed_response
    end

    ###
    # Add one or more trackers to a torrent
    #
    # If passing mulitple urls, pass them as an array.
    #
    def add_trackers torrent_hash, urls
      urls = Array(urls)
      # Ampersands in urls must be escaped.
      urls = urls.map { |url| url.gsub('&', '%26') }
      urls = urls.join('%0A')

      options = {
        body: "hash=#{torrent_hash}&urls=#{urls}"
      }

      self.class.post('/command/addTrackers', options)
    end

    ###
    # Get torrent contents (files data)
    #
    # Example response:
    #    [
    #      {
    #        "is_seed"=>false,
    #        "name"=>"Grimm.S04E12.720p.HDTV.X264-DIMENSION.mkv",
    #        "priority"=>1,
    #        "progress"=>0.0,
    #        "size"=>"825.4 MiB"
    #      }
    #    ]
    #
    def contents torrent_hash
      self.class.format :json
      self.class.get('/query/propertiesFiles/' + torrent_hash).parsed_response
    end

    ###
    # Get application transfer info
    #
    # Example response:
    #    {
    #      "dl_info"=>"D: 0 B/s/s - T: 657.8 KiB",
    #      "up_info"=>"U: 0 B/s/s - T: 0 B"
    #    }
    #
    def transfer_info
      self.class.format :json
      self.class.get('/query/transferInfo').parsed_response
    end

    ###
    # Get application preferences (options)
    #
    # Example response:
    #    {
    #      "alt_dl_limit"=>10,
    #      "alt_up_limit"=>10,
    #      "anonymous_mode"=>false,
    #      "autorun_enabled"=>false,
    #      "autorun_program"=>"",
    #      "bypass_local_auth"=>false,
    #      "dht"=>true,
    #      "dhtSameAsBT"=>true,
    #      "dht_port"=>6881,
    #      "dl_limit"=>-1,
    #      "dont_count_slow_torrents"=>false,
    #      "download_in_scan_dirs"=>[],
    #      "dyndns_domain"=>"changeme.dyndns.org",
    #      "dyndns_enabled"=>false,
    #      "dyndns_password"=>"",
    #      "dyndns_service"=>0,
    #      "dyndns_username"=>"",
    #      "enable_utp"=>true,
    #      "encryption"=>0,
    #      "export_dir"=>"",
    #      "export_dir_enabled"=>false,
    #      "incomplete_files_ext"=>false,
    #      "ip_filter_enabled"=>false,
    #      "ip_filter_path"=>"",
    #      "limit_tcp_overhead"=>false,
    #      "limit_utp_rate"=>true,
    #      "listen_port"=>6881,
    #      "locale"=>"en_US",
    #      "lsd"=>true,
    #      "mail_notification_auth_enabled"=>false,
    #      "mail_notification_email"=>"",
    #      "mail_notification_enabled"=>false,
    #      "mail_notification_password"=>"",
    #      "mail_notification_smtp"=>"smtp.changeme.com",
    #      "mail_notification_ssl_enabled"=>false,
    #      "mail_notification_username"=>"",
    #      "max_active_downloads"=>3,
    #      "max_active_torrents"=>5,
    #      "max_active_uploads"=>3,
    #      "max_connec"=>500,
    #      "max_connec_per_torrent"=>100,
    #      "max_uploads_per_torrent"=>4,
    #      "pex"=>true,
    #      "preallocate_all"=>false,
    #      "proxy_auth_enabled"=>false,
    #      "proxy_ip"=>"0.0.0.0",
    #      "proxy_password"=>"",
    #      "proxy_peer_connections"=>false,
    #      "proxy_port"=>8080,
    #      "proxy_type"=>-1,
    #      "proxy_username"=>"",
    #      "queueing_enabled"=>false,
    #      "save_path"=>"/home/jeff/Downloads",
    #      "scan_dirs"=>[],
    #      "schedule_from_hour"=>8,
    #      "schedule_from_min"=>0,
    #      "schedule_to_hour"=>20,
    #      "schedule_to_min"=>0,
    #      "scheduler_days"=>0,
    #      "scheduler_enabled"=>false,
    #      "ssl_cert"=>"",
    #      "ssl_key"=>"",
    #      "temp_path"=>"/home/jeff/Downloads/temp",
    #      "temp_path_enabled"=>false,
    #      "up_limit"=>50,
    #      "upnp"=>true,
    #      "use_https"=>false,
    #      "web_ui_password"=>"ae150cdc82b40c4373d2e15e0ffe8f67",
    #      "web_ui_port"=>8083,
    #      "web_ui_username"=>"admin"
    #    }
    #
    def preferences
      self.class.format :json
      self.class.get('/query/preferences').parsed_response
    end

    ###
    # Set application preferences
    #
    # Note: When setting password, pass it as plain text.
    # You can send only the key/value pairs you want to change (in a hash),
    # rather than the entire set of data.
    #
    def set_preferences pref_hash
      pref_hash = Hash(pref_hash)
      options = {
        body: "json=#{pref_hash.to_json}"
      }

      self.class.post('/command/setPreferences', options)
    end

    ###
    # Pause a torrent
    #
    def pause torrent_hash
      options = {
        body: "hash=#{torrent_hash}"
      }

      self.class.post('/command/pause', options)
    end

    ###
    # Pause all torrents
    #
    def pause_all
      self.class.post('/command/pauseAll')
    end

    ###
    # Resume downloading/seeding of a torrent
    #
    def resume torrent_hash
      options = {
        body: "hash=#{torrent_hash}"
      }

      self.class.post('/command/resume', options)
    end

    ###
    # Resume downloading/seeding of all torrents
    #
    def resume_all
      self.class.post('/command/resumeAll')
    end

    ###
    # Begin downloading one or more torrents.
    #
    # If passing mulitple urls, pass them as an array.
    #
    def download urls
      urls = Array(urls)
      urls = urls.join('%0A')

      options = {
        body: "urls=#{urls}"
      }

      self.class.post('/command/download', options)
    end

    ###
    # Delete one or more torrents AND THEIR DATA
    #
    # If passing multiple torrent hashes, pass them as an array.
    #
    def delete_torrent_and_data torrent_hashes
      torrent_hashes = Array(torrent_hashes)
      torrent_hashes = torrent_hashes.join('|')

      options = {
        body: "hashes=#{torrent_hashes}"
      }

      self.class.post('/command/deletePerm', options)
    end

    ###
    # Delete one or more torrents (doesn't delete their data)
    #
    # If passing multiple torrent hashes, pass them as an array.
    #
    def delete torrent_hashes
      torrent_hashes = Array(torrent_hashes)
      torrent_hashes = torrent_hashes.join('|')

      options = {
        body: "hashes=#{torrent_hashes}"
      }

      self.class.post('/command/delete', options)
    end

    ###
    # Recheck a torrent
    #
    def recheck torrent_hash
      options = {
        body: "hash=#{torrent_hash}"
      }

      self.class.post('/command/recheck', options)
    end

    # Set location for a torrent
    def set_location(torrent_hashes, path)
      torrent_hashes = Array(torrent_hashes)
      torrent_hashes = torrent_hashes.join('|')

      options = {
        body: { "hashes" => torrent_hashes, "location" => path },
      }

      self.class.post('/command/setLocation', options)
    end

    ###
    # Increase the priority of one or more torrents
    #
    # If passing multiple torrent hashes, pass them as an array.
    # Note: This does nothing unless queueing has been enabled
    # via preferences.
    #
    def increase_priority torrent_hashes
      torrent_hashes = Array(torrent_hashes)
      torrent_hashes = torrent_hashes.join('|')

      options = {
        body: "hashes=#{torrent_hashes}"
      }

      self.class.post('/command/increasePrio', options)
    end

    ###
    # Decrease the priority of one or more torrents
    #
    # If passing multiple torrent hashes, pass them as an array.
    # Note: This does nothing unless queueing has been enabled
    # via preferences.
    #
    def decrease_priority torrent_hashes
      torrent_hashes = Array(torrent_hashes)
      torrent_hashes = torrent_hashes.join('|')

      options = {
        body: "hashes=#{torrent_hashes}"
      }

      self.class.post('/command/decreasePrio', options)
    end

    ###
    # Increase the priority of one or more torrents to the maximum value
    #
    # If passing multiple torrent hashes, pass them as an array.
    # Note: This does nothing unless queueing has been enabled
    # via preferences.
    #
    def maximize_priority torrent_hashes
      torrent_hashes = Array(torrent_hashes)
      torrent_hashes = torrent_hashes.join('|')

      options = {
        body: "hashes=#{torrent_hashes}"
      }

      self.class.post('/command/topPrio', options)
    end

    ###
    # Decrease the priority of one or more torrents to the minimum value
    #
    # If passing multiple torrent hashes, pass them as an array.
    # Note: This does nothing unless queueing has been enabled
    # via preferences.
    #
    def minimize_priority torrent_hashes
      torrent_hashes = Array(torrent_hashes)
      torrent_hashes = torrent_hashes.join('|')

      options = {
        body: "hashes=#{torrent_hashes}"
      }

      self.class.post('/command/bottomPrio', options)
    end

    ###
    # Set the download priority of a file within a torrent
    #
    # file_id is a 0 based position of the file within the torrent
    #
    def set_file_priority torrent_hash, file_id, priority
      query = ["hash=#{torrent_hash}", "id=#{file_id}", "priority=#{priority}"]

      options = {
        body: query.join('&')
      }

      self.class.post('/command/setFilePrio', options)
    end

    ###
    # Get the application's global download limit
    #
    # A limit of 0 means unlimited.
    #
    # Returns an integer (bytes)
    #
    def global_download_limit
      self.class.format :json
      self.class.post('/command/getGlobalDlLimit').parsed_response
    end

    ###
    # Set the application's global download limit
    #
    # A limit of 0 means unlimited.
    #
    # limit: integer (bytes)
    #
    def set_global_download_limit limit
      query = "limit=#{limit}"

      options = {
        body: query
      }

      self.class.post('/command/setGlobalDlLimit', options)
    end

    ###
    # Get the application's global upload limit
    #
    # A limit of 0 means unlimited.
    #
    # Returns an integer (bytes)
    #
    def global_upload_limit
      self.class.format :json
      self.class.post('/command/getGlobalUpLimit').parsed_response
    end

    ###
    # Set the application's global upload limit
    #
    # A limit of 0 means unlimited.
    #
    # limit: integer (bytes)
    #
    def set_global_upload_limit limit
      query = "limit=#{limit}"

      options = {
        body: query
      }

      self.class.post('/command/setGlobalUpLimit', options)
    end

    ###
    # Get a torrent's download limit
    #
    # A limit of 0 means unlimited.
    #
    # Returns an integer (bytes)
    #
    def download_limit torrent_hash
      self.class.format :json

      options = {
        body: "hashes=#{torrent_hash}"
      }

      self.class
        .post('/command/getTorrentsDlLimit', options)
        .parsed_response[torrent_hash]
    end

    ###
    # Set a torrent's download limit
    #
    # A limit of 0 means unlimited.
    #
    # torrent_hash: string
    # limit: integer (bytes)
    #
    def set_download_limit torrent_hash, limit
      query = ["hashes=#{torrent_hash}", "limit=#{limit}"]

      options = {
        body: query.join('&')
      }

      self.class.post('/command/setTorrentsDlLimit', options)
    end

    ###
    # Get a torrent's upload limit
    #
    # A limit of 0 means unlimited.
    #
    # Returns an integer (bytes)
    #
    def upload_limit torrent_hash
      self.class.format :json

      options = {
        body: "hashes=#{torrent_hash}"
      }

      self.class
        .post('/command/getTorrentsUpLimit', options)
        .parsed_response[torrent_hash]
    end

    ###
    # Set a torrent's upload limit
    #
    # A limit of 0 means unlimited.
    #
    # torrent_hash: string
    # limit: integer (bytes)
    #
    def set_upload_limit torrent_hash, limit
      query = ["hashes=#{torrent_hash}", "limit=#{limit}"]

      options = {
        body: query.join('&')
      }

      self.class.post('/command/setTorrentsUpLimit', options)
    end

  private

    def md5 str
      Digest::MD5.hexdigest str
    end
  end
end

