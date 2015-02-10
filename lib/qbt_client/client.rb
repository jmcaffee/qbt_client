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
require 'digest'


module QbtClient

  class Client
    include HTTParty

    #debug_output $stdout

    ###
    # constructor
    #
    def initialize(ip, port, user, pass)
      @ip         = ip
      @port       = port
      @user       = user
      @pass       = pass

      self.class.digest_auth(user, pass)
      self.class.base_uri "#{ip}:#{port}"
    end

    ###
    # Get array of all torrents
    #
    def torrent_list
      self.class.format :json
      self.class.get('/json/torrents').parsed_response
    end

    def torrent_data torrent_hash
      torrents = torrent_list

      torrents.each do |t|
        if t["hash"] == torrent_hash
          return t
        end
      end
    end

    def properties torrent_hash
      self.class.format :json
      self.class.get('/json/propertiesGeneral/' + torrent_hash).parsed_response
    end

    def trackers torrent_hash
      self.class.format :json
      self.class.get('/json/propertiesTrackers/' + torrent_hash).parsed_response
    end

    def contents torrent_hash
      self.class.format :json
      self.class.get('/json/propertiesFiles/' + torrent_hash).parsed_response
    end

    def transfer_info
      self.class.format :json
      self.class.get('/json/transferInfo').parsed_response
    end

    def preferences
      self.class.format :json
      self.class.get('/json/preferences').parsed_response
    end

    def preferences= pref_hash
      pref_hash = Hash(pref_hash)
      options = {
        body: "json=#{pref_hash.to_json}"
      }

      self.class.post('/command/setPreferences', options)
    end

    def pause torrent_hash
      options = {
        body: "hash=#{torrent_hash}"
      }

      self.class.post('/command/pause', options)
    end

    def pause_all
      self.class.post('/command/pauseall')
    end

    def resume torrent_hash
      options = {
        body: "hash=#{torrent_hash}"
      }

      self.class.post('/command/resume', options)
    end

    def resume_all
      self.class.post('/command/resumeall')
    end

    def download urls
      urls = Array(urls)
      urls = urls.join('%0A')

      options = {
        body: "urls=#{urls}"
      }

      self.class.post('/command/download', options)
    end

    def delete_torrent_and_data torrent_hashes
      torrent_hashes = Array(torrent_hashes)
      torrent_hashes = torrent_hashes.join('|')

      options = {
        body: "hashes=#{torrent_hashes}"
      }

      self.class.post('/command/deletePerm', options)
    end

    def delete torrent_hashes
      torrent_hashes = Array(torrent_hashes)
      torrent_hashes = torrent_hashes.join('|')

      options = {
        body: "hashes=#{torrent_hashes}"
      }

      self.class.post('/command/delete', options)
    end

    def recheck torrent_hash
      options = {
        body: "hash=#{torrent_hash}"
      }

      self.class.post('/command/recheck', options)
    end

    def increase_priority torrent_hashes
      torrent_hashes = Array(torrent_hashes)
      torrent_hashes = torrent_hashes.join('|')

      options = {
        body: "hashes=#{torrent_hashes}"
      }

      self.class.post('/command/increasePrio', options)
    end

    def decrease_priority torrent_hashes
      torrent_hashes = Array(torrent_hashes)
      torrent_hashes = torrent_hashes.join('|')

      options = {
        body: "hashes=#{torrent_hashes}"
      }

      self.class.post('/command/decreasePrio', options)
    end

    def maximize_priority torrent_hashes
      torrent_hashes = Array(torrent_hashes)
      torrent_hashes = torrent_hashes.join('|')

      options = {
        body: "hashes=#{torrent_hashes}"
      }

      self.class.post('/command/topPrio', options)
    end

    def minimize_priority torrent_hashes
      torrent_hashes = Array(torrent_hashes)
      torrent_hashes = torrent_hashes.join('|')

      options = {
        body: "hashes=#{torrent_hashes}"
      }

      self.class.post('/command/bottomPrio', options)
    end

  private

    def md5 str
      Digest::MD5.hexdigest str
    end
  end
end

