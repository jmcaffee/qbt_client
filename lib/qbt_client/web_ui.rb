##############################################################################
# File::    web_ui.rb
# Purpose:: Web UI client for qBittorrent.
#
# Author::    Jeff McAffee 2015-02-07
# Copyright:: Copyright (c) 2015, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require 'json/pure'
require 'httparty'
require 'digest'


module QbtClient

  class WebUI
    include HTTParty

    # Uncomment this line to see network transaction data:
    #debug_output $stdout
    #
    # For specific areas of code, use the following to turn on debug network output:
    # where value is:
    #   $stdout - prints to the console
    #   nil     - turns it off.
    #
    #     self.class.debug_output value
    #

    ###
    # constructor
    #
    def initialize(ip, port, user, pass)
      @ip         = ip
      @port       = port
      @user       = user
      @pass       = pass

      self.class.base_uri "#{ip}:#{port}"
    end

    def login(user = nil, pass = nil)
      user ||= @user
      pass ||= @pass

      self.class.format :json

      payload = {
        body: "username=#{user}&password=#{pass}"
      }
      response = self.class.post('/login', payload)

      sid_cookie = response.headers["set-cookie"]
      #if cookie_needed? and ! sid_cookie.nil?
      if ! sid_cookie.nil?
        self.class.headers "cookie" => sid_cookie
      end
    end

    private

    def cookie_needed?
      self.class.headers["cookie"].nil?
    end

    def authenticated_get(url)
      login if cookie_needed?
      self.class.get(url)
    end

    def authenticated_post(url, body = {})
      login if cookie_needed?
      self.class.post(url, body)
    end

    public

    ###
    # Return the webui api version of the current webui
    #
    # Returns 1 if webui api version is < 2
    #
    def api_version
      self.class.format :plain
      aver = self.class.get('/version/api').parsed_response

      # We'll receive nil if the webui doesn't support /version/api.
      # /version/api was added as of version 2, so return 1 if nil.
      return "1" if aver.nil?
      aver
    end

    ###
    # Return the minimum api version supported by the current webui
    #
    # Returns nil if webui api version is < 2
    #
    def api_min_version
      self.class.format :plain
      self.class.get('/version/api_min').parsed_response
    end

    ###
    # Return the qBitTorrent application version
    #
    # Returns nil if webui api version is < 2
    #
    def app_version
      self.class.format :plain
      self.class.get('/version/qbittorrent').parsed_response
    end

    ###
    # Get array of all torrents
    #
    # filter_options: optional hash of values
    #   possible filters (more than one can be used at a time):
    #     - filter (string): all, downloading, completed, paused, active, inactive
    #       - Note that 'paused' doesn't seem to work,
    #         'pausedDL' does - use 'all', or a valid value for the 'state' key.
    #     - label (string): get torrents with the given label
    #         (empty string means "unlabeled"; no "label" param means "any label")
    #     - sort (string): sort torrents by given key
    #     - reverse (bool): enable reverse sorting
    #     - limit (int): limit number of torrents returned
    #     - offset (int): set offset (if less than 0, offset from end)#
    #
    # Example response:
    #
    #   [
    #     {
    #       "dlspeed"=>0,
    #       "eta"=>8640000,
    #       "f_l_piece_prio"=>false,
    #       "force_start"=>false,
    #       "hash"=>"156b69b8643bd11849a5d8f2122e13fbb61bd041",
    #       "label"=>"",
    #       "name"=>"slackware64-14.1-iso",
    #       "num_complete"=>196,
    #       "num_incomplete"=>9,
    #       "num_leechs"=>0,
    #       "num_seeds"=>0,
    #       "priority"=>-1,
    #       "progress"=>0.0,
    #       "ratio"=>0.0,
    #       "seq_dl"=>false,
    #       "size"=>2439219966,
    #       "state"=>"pausedDL",
    #       "super_seeding"=>false,
    #       "upspeed"=>0
    #     },
    #     {
    #       "dlspeed"=>0,
    #       "eta"=>8640000,
    #       "f_l_piece_prio"=>false,
    #       "force_start"=>false,
    #       "hash"=>"61ace93a9ae877191460a616b19e4eeb6dba1747",
    #       "label"=>"",
    #       "name"=>"KNOPPIX_V7.4.2DVD-2014-09-28-EN",
    #       "num_complete"=>-1,
    #       "num_incomplete"=>-1,
    #       "num_leechs"=>0,
    #       "num_seeds"=>0,
    #       "priority"=>-1,
    #       "progress"=>0.0,
    #       "ratio"=>0.0,
    #       "seq_dl"=>false,
    #       "size"=>4259006327,
    #       "state"=>"pausedDL",
    #       "super_seeding"=>false,
    #       "upspeed"=>0
    #     }
    #   ]
    #
    #  Possible values of 'state':
    #    error - some error occurred, applies to paused torrents
    #    pausedUP - torrent is paused and has finished downloading
    #    pausedDL - torrent is paused and has NOT finished downloading
    #    queuedUP - queuing is enabled and torrent is queued for upload
    #    queuedDL - queuing is enabled and torrent is queued for download
    #    uploading - torrent is being seeded and data is being transfered
    #    stalledUP - torrent is being seeded, but no connection were made
    #    checkingUP - torrent has finished downloading and is being checked;
    #                 this status also applies to preallocation (if enabled)
    #                 and checking resume data on qBt startup
    #    checkingDL - same as checkingUP, but torrent has NOT finished downloading
    #    downloading - torrent is being downloaded and data is being transfered
    #    stalledDL - torrent is being downloaded, but no connection were made
    #
    # Note: -1 is returned for integers when info is not known.
    #
    def torrent_list filter_options = {}
      filters = []

      filter  = filter_options.fetch :filter, ""
      label   = filter_options.fetch :label, nil
      sort    = filter_options.fetch :sort, ""
      reverse = filter_options.fetch :reverse, nil
      limit   = filter_options.fetch :limit, nil
      offset  = filter_options.fetch :offset, nil

      if ! filter.empty?
        filters << "filter=#{filter}"
      end
      if ! label.nil?
        filters << "label=#{label}"
      end
      if ! sort.empty?
        filters << "sort=#{sort}"
      end
      if ! reverse.nil?
        filters << "reverse=#{reverse}"
      end
      if ! limit.nil?
        filters << "limit=#{limit}"
      end
      if ! offset.nil?
        filters << "offset=#{offset}"
      end

      if filters.count > 0
        filters = filters.join("&")
        filters = "?" + filters
      else
        filters = ""
      end

      self.class.format :json
      authenticated_get('/query/torrents' + filters).parsed_response
    end

    ###
    # Get hash of torrent data
    #
    # Example response:
    #   {
    #     "dlspeed"=>12713,
    #     "eta"=>8640000,
    #     "f_l_piece_prio"=>false,
    #     "force_start"=>false,
    #     "hash"=>"156b69b8643bd11849a5d8f2122e13fbb61bd041",
    #     "label"=>"",
    #     "name"=>"slackware64-14.1-iso",
    #     "num_complete"=>194,
    #     "num_incomplete"=>9,
    #     "num_leechs"=>0,
    #     "num_seeds"=>0,
    #     "priority"=>-1,
    #     "progress"=>8.73197e-05,
    #     "ratio"=>0.0,
    #     "seq_dl"=>false,
    #     "size"=>2439219966,
    #     "state"=>"pausedDL",
    #     "super_seeding"=>false,
    #     "upspeed"=>0
    #   }
    #
    def torrent_data torrent_hash
      torrents = torrent_list

      torrents.each do |t|
        if t["hash"] == torrent_hash
          return t
        end
      end
    end

    ###
    # Retrieve only the data that has changed since the last call
    #
    # Example response (full):
    #
    #   {
    #     "full_update"=>true,
    #     "labels"=>[],
    #     "rid"=>1,
    #     "server_state"=>
    #       {
    #         "connection_status"=>"connected",
    #         "dht_nodes"=>168,
    #         "dl_info_data"=>2204443340,
    #         "dl_info_speed"=>172402,
    #         "dl_rate_limit"=>0,
    #         "queueing"=>false,
    #         "refresh_interval"=>1500,
    #         "up_info_data"=>110186,
    #         "up_info_speed"=>0,
    #         "up_rate_limit"=>51200,
    #         "use_alt_speed_limits"=>false},
    #     "torrents"=>
    #       {
    #         "156b69b8643bd11849a5d8f2122e13fbb61bd041"=>
    #           {
    #             "dlspeed"=>172285,
    #             "eta"=>10611,
    #             "f_l_piece_prio"=>false,
    #             "force_start"=>false,
    #             "label"=>"",
    #             "name"=>"slackware64-14.1-iso",
    #             "num_complete"=>158,
    #             "num_incomplete"=>8,
    #             "num_leechs"=>9,
    #             "num_seeds"=>22,
    #             "priority"=>-1,
    #             "progress"=>2.02524e-07,
    #             "ratio"=>0.0,
    #             "seq_dl"=>false,
    #             "size"=>2439219966,
    #             "state"=>"downloading",
    #             "super_seeding"=>false,
    #             "upspeed"=>0},
    #         "61ace93a9ae877191460a616b19e4eeb6dba1747"=>
    #           {
    #             "dlspeed"=>0,
    #             "eta"=>8640000,
    #             "f_l_piece_prio"=>false,
    #             "force_start"=>false,
    #             "label"=>"",
    #             "name"=>"KNOPPIX_V7.4.2DVD-2014-09-28-EN",
    #             "num_complete"=>-1,
    #             "num_incomplete"=>-1,
    #             "num_leechs"=>0,
    #             "num_seeds"=>2,
    #             "priority"=>-1,
    #             "progress"=>0.0,
    #             "ratio"=>0.0,
    #             "seq_dl"=>false,
    #             "size"=>4259006327,
    #             "state"=>"stalledDL",
    #             "super_seeding"=>false,
    #             "upspeed"=>0}
    #       }
    #   }
    #
    # Example response (partial):
    #
    #   {
    #     "rid"=>2,
    #     "server_state"=>
    #       {
    #         "dl_info_data"=>2222347987,
    #         "dl_info_speed"=>1533496},
    #     "torrents"=>
    #       {
    #         "156b69b8643bd11849a5d8f2122e13fbb61bd041"=>
    #           {
    #             "dlspeed"=>1330010,
    #             "eta"=>2005,
    #             "num_leechs"=>4,
    #             "num_seeds"=>44,
    #             "progress"=>0.00307702},
    #         "61ace93a9ae877191460a616b19e4eeb6dba1747"=>
    #           {
    #             "dlspeed"=>203471,
    #             "eta"=>28296,
    #             "num_leechs"=>5,
    #             "num_seeds"=>15,
    #             "progress"=>6.43343e-08,
    #             "state"=>"downloading"}
    #       }
    #   }
    def get_partial_data rid = nil
      # Use the last rid value or 0 or user passed value
      rid ||= @rid ||= 0

      res = authenticated_get('/sync/maindata' + "?rid=#{rid}")

      # Store the rid for the next call
      @rid = res["rid"]

      res
    end
    ###
    # Get properties of a torrent (different data than what's returned
    # in #torrent_list).
    #
    # Example response:
    #    {
    #       "comment"=>"Visit us: https://eztv.ch/ - Bitcoin: 1EZTVaGQ6UsjYJ9fwqGnd45oZ6HGT7WKZd",
    #       "creation_date"=>1383701567,
    #       "dl_limit"=>-1,
    #       "nb_connections"=>0,
    #       "nb_connections_limit"=>100,
    #       "piece_size"=>2097152,
    #       "save_path"=>"/home/jeff/Downloads/",
    #       "seeding_time"=>0,
    #       "share_ratio"=>0.0,
    #       "time_elapsed"=>2,
    #       "total_downloaded"=>60755,
    #       "total_downloaded_session"=>89332,
    #       "total_uploaded"=>0,
    #       "total_uploaded_session"=>0,
    #       "total_wasted"=>150,
    #       "up_limit"=>-1
    #    }
    #
    def properties torrent_hash
      self.class.format :json
      authenticated_get('/query/propertiesGeneral/' + torrent_hash).parsed_response
    end

    ###
    # Get tracker data for a torrent
    #
    # Example response:
    #
    #   [
    #     {
    #       "msg"=>"",
    #       "num_peers"=>200,
    #       "status"=>"Working",
    #       "url"=>"http://tracker2.transamrit.net:8082/announce"},
    #     {
    #       "msg"=>"",
    #       "num_peers"=>0,
    #       "status"=>"Not contacted yet",
    #       "url"=>"http://tracker1.transamrit.net:8082/announce"},
    #     {
    #       "msg"=>"",
    #       "num_peers"=>0,
    #       "status"=>"Not contacted yet",
    #       "url"=>"http://tracker3.transamrit.net:8082/announce"}
    #   ]
    #
    def trackers torrent_hash
      self.class.format :json
      authenticated_get('/query/propertiesTrackers/' + torrent_hash).parsed_response
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

      authenticated_post('/command/addTrackers', options)
    end

    ###
    # Get torrent contents (files data)
    #
    # Example response:
    #
    #   [
    #     {
    #       "is_seed"=>false,
    #       "name"=>"slackware64-14.1-iso/slackware64-14.1-install-dvd.iso",
    #       "priority"=>1,
    #       "progress"=>0.0,
    #       "size"=>2438987776},
    #     {
    #       "name"=>"slackware64-14.1-iso/slackware64-14.1-install-dvd.iso.asc",
    #       "priority"=>1,
    #       "progress"=>0.0,
    #       "size"=>198},
    #     {
    #       "name"=>"slackware64-14.1-iso/slackware64-14.1-install-dvd.iso.md5",
    #       "priority"=>1,
    #       "progress"=>0.0,
    #       "size"=>67},
    #     {
    #       "name"=>"slackware64-14.1-iso/slackware64-14.1-install-dvd.iso.txt",
    #       "priority"=>1,
    #       "progress"=>0.0,
    #       "size"=>231925}
    #   ]
    #
    def contents torrent_hash
      self.class.format :json
      authenticated_get('/query/propertiesFiles/' + torrent_hash).parsed_response
    end

    ###
    # Get application transfer info
    #
    # Example response:
    #
    #   {
    #     "connection_status"=>"connected",
    #     "dht_nodes"=>170,
    #     "dl_info_data"=>1925752335,
    #     "dl_info_speed"=>0,
    #     "dl_rate_limit"=>0,
    #     "up_info_data"=>110186,
    #     "up_info_speed"=>0,
    #     "up_rate_limit"=>51200
    #   }
    #
    def transfer_info
      self.class.format :json
      authenticated_get('/query/transferInfo').parsed_response
    end

    ###
    # Get application preferences (options)
    #
    # Example response:
    #
    #   {
    #     "alt_dl_limit"=>10,
    #     "alt_up_limit"=>10,
    #     "anonymous_mode"=>false,
    #     "autorun_enabled"=>false,
    #     "autorun_program"=>"",
    #     "bypass_local_auth"=>false,
    #     "dht"=>true,
    #     "dl_limit"=>-1,
    #     "dont_count_slow_torrents"=>false,
    #     "download_in_scan_dirs"=>[],
    #     "dyndns_domain"=>"changeme.dyndns.org",
    #     "dyndns_enabled"=>false,
    #     "dyndns_password"=>"",
    #     "dyndns_service"=>0,
    #     "dyndns_username"=>"",
    #     "enable_utp"=>true,
    #     "encryption"=>0,
    #     "export_dir"=>"",
    #     "export_dir_enabled"=>false,
    #     "incomplete_files_ext"=>false,
    #     "ip_filter_enabled"=>false,
    #     "ip_filter_path"=>"",
    #     "limit_tcp_overhead"=>false,
    #     "limit_utp_rate"=>true,
    #     "listen_port"=>6881,
    #     "locale"=>"en",
    #     "lsd"=>true,
    #     "mail_notification_auth_enabled"=>false,
    #     "mail_notification_email"=>"",
    #     "mail_notification_enabled"=>false,
    #     "mail_notification_password"=>"",
    #     "mail_notification_smtp"=>"smtp.changeme.com",
    #     "mail_notification_ssl_enabled"=>false,
    #     "mail_notification_username"=>"",
    #     "max_active_downloads"=>3,
    #     "max_active_torrents"=>5,
    #     "max_active_uploads"=>3,
    #     "max_connec"=>500,
    #     "max_connec_per_torrent"=>100,
    #     "max_uploads_per_torrent"=>4,
    #     "pex"=>true,
    #     "preallocate_all"=>false,
    #     "proxy_auth_enabled"=>false,
    #     "proxy_ip"=>"0.0.0.0",
    #     "proxy_password"=>"",
    #     "proxy_peer_connections"=>false,
    #     "proxy_port"=>8080,
    #     "proxy_type"=>-1,
    #     "proxy_username"=>"",
    #     "queueing_enabled"=>false,
    #     "save_path"=>"/home/jeff/Downloads",
    #     "scan_dirs"=>[],
    #     "schedule_from_hour"=>8,
    #     "schedule_from_min"=>0,
    #     "schedule_to_hour"=>20,
    #     "schedule_to_min"=>0,
    #     "scheduler_days"=>0,
    #     "scheduler_enabled"=>false,
    #     "ssl_cert"=>"",
    #     "ssl_key"=>"",
    #     "temp_path"=>"/home/jeff/Downloads/temp",
    #     "temp_path_enabled"=>false,
    #     "up_limit"=>50,
    #     "upnp"=>true,
    #     "use_https"=>false,
    #     "web_ui_password"=>"900150983cd24fb0d6963f7d28e17f72",
    #     "web_ui_port"=>8083,
    #     "web_ui_username"=>"admin"
    #   }
    #
    #     Possible values of 'scheduler_days':
    #       0 - every day
    #       1 - every weekday
    #       2 - every weekend
    #       3 - every Monday
    #       4 - every Tuesday
    #       5 - every Wednesday
    #       6 - every Thursday
    #       7 - every Friday
    #       8 - every Saturday
    #       9 - every Sunday
    #
    #     Possible values of 'dyndns_service':
    #       0 - use DyDNS
    #       1 - use NOIP
    #
    #     Possible values of 'encryption'
    #       0 - prefer encryption (default): allow both encrypted and unencrypted connections
    #       1 - force encryption on: allow only encrypted connections
    #       2 - force encryption off: allow only unencrypted connection
    #
    #     Possible values of 'proxy_type':
    #      -1 - proxy is disabled
    #       1 - HTTP proxy without authentication
    #       2 - SOCKS5 proxy without authentication
    #       3 - HTTP proxy with authentication
    #       4 - SOCKS5 proxy with authentication
    #       5 - SOCKS4 proxy without authentication
    #
    def preferences
      self.class.format :json
      authenticated_get('/query/preferences').parsed_response
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

      authenticated_post('/command/setPreferences', options)
    end

    ###
    # Pause a torrent
    #
    def pause torrent_hash
      options = {
        body: "hash=#{torrent_hash}"
      }

      authenticated_post('/command/pause', options)
    end

    ###
    # Pause all torrents
    #
    def pause_all
      authenticated_post('/command/pauseAll')
    end

    ###
    # Resume downloading/seeding of a torrent
    #
    def resume torrent_hash
      options = {
        body: "hash=#{torrent_hash}"
      }

      authenticated_post('/command/resume', options)
    end

    ###
    # Resume downloading/seeding of all torrents
    #
    def resume_all
      authenticated_post('/command/resumeAll')
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

      authenticated_post('/command/download', options)
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

      authenticated_post('/command/deletePerm', options)
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

      authenticated_post('/command/delete', options)
    end

    ###
    # Recheck a torrent
    #
    def recheck torrent_hash
      options = {
        body: "hash=#{torrent_hash}"
      }

      authenticated_post('/command/recheck', options)
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

      authenticated_post('/command/increasePrio', options)
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

      authenticated_post('/command/decreasePrio', options)
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

      authenticated_post('/command/topPrio', options)
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

      authenticated_post('/command/bottomPrio', options)
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

      authenticated_post('/command/setFilePrio', options)
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
      authenticated_post('/command/getGlobalDlLimit').parsed_response
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

      authenticated_post('/command/setGlobalDlLimit', options)
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
      authenticated_post('/command/getGlobalUpLimit').parsed_response
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

      authenticated_post('/command/setGlobalUpLimit', options)
    end

    ###
    # Get a torrent's download limit
    #
    # A limit of 0 means unlimited.
    #
    # Returns an integer (bytes)
    #
    def download_limit torrent_hash
      download_limits(torrent_hash)[torrent_hash]
    end

    ###
    # Get download limits for one or more torrents
    #
    # If passing multiple torrent hashes, pass them as an array.
    #
    # A limit of 0 means unlimited.
    #
    # Returns a hash: hash keys = torrent hash, hash values: integer (bytes)
    #
    # Example response:
    #
    #   {
    #     "156b69b8643bd11849a5d8f2122e13fbb61bd041"=>0,
    #     "61ace93a9ae877191460a616b19e4eeb6dba1747"=>0
    #   }
    #
    def download_limits torrent_hashes
      torrent_hashes = Array(torrent_hashes)
      torrent_hashes = torrent_hashes.join('|')

      self.class.format :json

      options = {
        body: "hashes=#{torrent_hashes}"
      }

      authenticated_post('/command/getTorrentsDlLimit', options).parsed_response
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
      set_download_limits torrent_hash, limit
    end

    ###
    # Set download limits for one or more torrents
    #
    # If passing multiple torrent hashes, pass them as an array.
    #
    # A limit of 0 means unlimited.
    #
    # torrent_hashes: string for single hash or array of one or more hashes
    # limit: integer (bytes)
    #
    def set_download_limits torrent_hashes, limit
      torrent_hashes = Array(torrent_hashes)
      torrent_hashes = torrent_hashes.join('|')

      query = ["hashes=#{torrent_hashes}", "limit=#{limit}"]

      options = {
        body: query.join('&')
      }

      authenticated_post('/command/setTorrentsDlLimit', options)
    end

    ###
    # Get a torrent's upload limit
    #
    # A limit of 0 means unlimited.
    #
    # Returns an integer (bytes)
    #
    def upload_limit torrent_hash
      upload_limits(torrent_hash)[torrent_hash]
    end

    ###
    # Get upload limits for one or more torrents
    #
    # If passing multiple torrent hashes, pass them as an array.
    #
    # A limit of 0 means unlimited.
    #
    # torrent_hashes: string for single hash or array of one or more hashes
    #
    # Example response:
    #
    #   {
    #     "156b69b8643bd11849a5d8f2122e13fbb61bd041"=>0,
    #     "61ace93a9ae877191460a616b19e4eeb6dba1747"=>0
    #   }
    #
    def upload_limits torrent_hashes
      torrent_hashes = Array(torrent_hashes)
      torrent_hashes = torrent_hashes.join('|')

      self.class.format :json

      options = {
        body: "hashes=#{torrent_hashes}"
      }

      authenticated_post('/command/getTorrentsUpLimit', options).parsed_response
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
      set_upload_limits torrent_hash, limit
    end

    ###
    # Set upload limits for one or more torrents
    #
    # If passing multiple torrent hashes, pass them as an array.
    #
    # A limit of 0 means unlimited.
    #
    # torrent_hashes: string for single hash or array of one or more hashes
    # limit: integer (bytes)
    #
    def set_upload_limits torrent_hashes, limit
      torrent_hashes = Array(torrent_hashes)
      torrent_hashes = torrent_hashes.join('|')

      query = ["hashes=#{torrent_hashes}", "limit=#{limit}"]

      options = {
        body: query.join('&')
      }

      self.class.format :json
      authenticated_post('/command/setTorrentsUpLimit', options)
    end

    ###
    # Toggle sequential download state
    #
    # torrent_hashes: string for single hash or array of one or more hashes
    #
    def toggle_sequential_download torrent_hashes
      torrent_hashes = Array(torrent_hashes)
      torrent_hashes = torrent_hashes.join('|')

      options = {
        body: "hashes=#{torrent_hashes}"
      }

      self.class.format :json
      authenticated_post('/command/toggleSequentialDownload', options)
    end

    ###
    # Toggle first/last piece priority state
    #
    # torrent_hashes: string for single hash or array of one or more hashes
    #
    def toggle_first_last_piece_priority torrent_hashes
      torrent_hashes = Array(torrent_hashes)
      torrent_hashes = torrent_hashes.join('|')

      options = {
        body: "hashes=#{torrent_hashes}"
      }

      self.class.format :json
      authenticated_post('/command/toggleFirstLastPiecePrio', options)
    end

    ###
    # Set/unset force_start flag on one or more torrents
    #
    # torrent_hashes: string for single hash or array of one or more hashes
    # value: true/false
    #
    def set_force_start torrent_hashes, value
      torrent_hashes = Array(torrent_hashes)
      torrent_hashes = torrent_hashes.join('|')

      options = {
        body: "hashes=#{torrent_hashes}&value=#{value}"
      }

      self.class.format :json
      authenticated_post('/command/setForceStart', options)
    end

  private

    def md5 str
      Digest::MD5.hexdigest str
    end
  end
end

