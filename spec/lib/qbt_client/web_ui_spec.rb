require 'spec_helper'
include QbtClient

describe WebUI do

  let(:example_torrent_data) {
    [
      {
          "dlspeed"=>"3.1 MiB/s",
          "eta"=>"9m",
          "hash"=>"156b69b8643bd11849a5d8f2122e13fbb61bd041",
          "name"=>"slackware64-14.1-iso",
          "num_leechs"=>"1 (14)",
          "num_seeds"=>"97 (270)",
          "priority"=>"*",
          "progress"=>0.172291,
          "ratio"=>"0.0",
          "size"=>"2.2 GiB",
          "state"=>"downloading",
          "upspeed"=>"0 B/s"
      },
      {
        "dlspeed"=>"1.8 KiB/s",
        "eta"=>"28d 1h",
        "hash"=>"1fe5775d32d3e58e48b3a96dd2883c5250882cda",
        "name"=>"Grimm.S04E12.720p.HDTV.X264-DIMENSION.mkv",
        "num_leechs"=>"7 (471)",
        "num_seeds"=>"15 (1866)",
        "priority"=>"*",
        "progress"=>1.53669e-07,
        "ratio"=>"0.0",
        "size"=>"825.4 MiB",
        "state"=>"downloading",
        "upspeed"=>"0 B/s"
      }
    ]
  }

  context "#torrent_list" do

    it "returns array of torrents" do
      hash, name = given_a_paused_downloading_torrent

      client = WebUI.new(test_ip, test_port, test_user, test_pass)
      list = client.torrent_list

      expect(list.class).to eq Array
      expect(list[0]['dlspeed']).to_not eq nil
    end
  end

  context "#torrent_data" do

    it "returns data for a specific torrent in Hash object" do
      hash, name = given_a_paused_downloading_torrent

      client = WebUI.new(test_ip, test_port, test_user, test_pass)
      data = client.torrent_data hash

      expect(data.class).to eq Hash
      expect(data["name"].include?(name)).to eq true
    end
  end

  let(:example_torrent_general_properties) {
    {
      "comment"=>"Visit us: https://eztv.ch/ - Bitcoin: 1EZTVaGQ6UsjYJ9fwqGnd45oZ6HGT7WKZd",
      "creation_date"=>"Friday, February 6, 2015 8:01:22 PM MST",
      "dl_limit"=>"∞",
      "nb_connections"=>"0 (100 max)",
      "piece_size"=>"512.0 KiB",
      "save_path"=>"/home/jeff/Downloads/",
      "share_ratio"=>"0.0",
      "time_elapsed"=>"< 1m",
      "total_downloaded"=>"646.8 KiB (657.8 KiB this session)",
      "total_uploaded"=>"0 B (0 B this session)",
      "total_wasted"=>"428 B",
      "up_limit"=>"∞"
    }
  }

  context "#properties" do

    it "returns torrent properties in Hash object" do
      hash, name = given_a_paused_downloading_torrent

      client = WebUI.new(test_ip, test_port, test_user, test_pass)
      res = client.properties hash

      expect(res.class).to eq Hash
      expect(res['save_path']).to_not eq nil
    end
  end

  let(:example_tracker_data) {
    [
      {
        "msg"=>"",
        "num_peers"=>"0",
        "status"=>"Working",
        "url"=>"udp://open.demonii.com:1337"},
      {
        "msg"=>"",
        "num_peers"=>"0",
        "status"=>"Not contacted yet",
        "url"=>"udp://tracker.coppersurfer.tk:6969"},
      {
        "msg"=>"",
        "num_peers"=>"0",
        "status"=>"Not contacted yet",
        "url"=>"udp://tracker.leechers-paradise.org:6969"},
      {
        "msg"=>"",
        "num_peers"=>"0",
        "status"=>"Not contacted yet",
        "url"=>"udp://exodus.desync.com:6969"}
    ]
  }

  context "#trackers" do

    it "returns tracker data in Array of Hashes" do
      hash, name = given_a_paused_downloading_torrent

      client = WebUI.new(test_ip, test_port, test_user, test_pass)
      res = client.trackers hash

      expect(res.class).to eq Array
      expect(res[0].class).to eq Hash
      expect(res[0]['msg']).to_not eq nil
      expect(res[0]['status']).to_not eq nil
      expect(res[0]['url']).to_not eq nil
    end
  end

  context "#add_trackers" do

    it "add one or more trackers to a torrent" do
      expect(false).to eq true
    end
  end

  let(:example_contents_data) {
    [
      {
        "is_seed"=>false,
        "name"=>"Grimm.S04E12.720p.HDTV.X264-DIMENSION.mkv",
        "priority"=>1,
        "progress"=>0.0,
        "size"=>"825.4 MiB"
      }
    ]
  }

  context "#contents" do

    it "returns Array of Hashes, one for each file in torrent" do
      hash, name = given_a_paused_downloading_torrent

      client = WebUI.new(test_ip, test_port, test_user, test_pass)
      res = client.contents hash

      expect(res.class).to eq Array
      expect(res[0].class).to eq Hash
      expect(res[0]['is_seed']).to_not eq nil
      expect(res[0]['name']).to_not eq nil
    end
  end

  let(:example_transfer_data) {
    {
      "dl_info"=>"D: 0 B/s/s - T: 657.8 KiB",
      "up_info"=>"U: 0 B/s/s - T: 0 B"
    }
  }

  context "#transfer_info" do

    it "returns hash" do
      hash, name = given_a_paused_downloading_torrent

      client = WebUI.new(test_ip, test_port, test_user, test_pass)
      res = client.transfer_info

      expect(res.class).to eq Hash
      expect(res['dl_info']).to_not eq nil
      expect(res['up_info']).to_not eq nil
    end
  end

  let(:example_preferences_data) {
    {
      "alt_dl_limit"=>10,
      "alt_up_limit"=>10,
      "anonymous_mode"=>false,
      "autorun_enabled"=>false,
      "autorun_program"=>"",
      "bypass_local_auth"=>false,
      "dht"=>true,
      "dhtSameAsBT"=>true,
      "dht_port"=>6881,
      "dl_limit"=>-1,
      "dont_count_slow_torrents"=>false,
      "download_in_scan_dirs"=>[],
      "dyndns_domain"=>"changeme.dyndns.org",
      "dyndns_enabled"=>false,
      "dyndns_password"=>"",
      "dyndns_service"=>0,
      "dyndns_username"=>"",
      "enable_utp"=>true,
      "encryption"=>0,
      "export_dir"=>"",
      "export_dir_enabled"=>false,
      "incomplete_files_ext"=>false,
      "ip_filter_enabled"=>false,
      "ip_filter_path"=>"",
      "limit_tcp_overhead"=>false,
      "limit_utp_rate"=>true,
      "listen_port"=>6881,
      "locale"=>"en_US",
      "lsd"=>true,
      "mail_notification_auth_enabled"=>false,
      "mail_notification_email"=>"",
      "mail_notification_enabled"=>false,
      "mail_notification_password"=>"",
      "mail_notification_smtp"=>"smtp.changeme.com",
      "mail_notification_ssl_enabled"=>false,
      "mail_notification_username"=>"",
      "max_active_downloads"=>3,
      "max_active_torrents"=>5,
      "max_active_uploads"=>3,
      "max_connec"=>500,
      "max_connec_per_torrent"=>100,
      "max_uploads_per_torrent"=>4,
      "pex"=>true,
      "preallocate_all"=>false,
      "proxy_auth_enabled"=>false,
      "proxy_ip"=>"0.0.0.0",
      "proxy_password"=>"",
      "proxy_peer_connections"=>false,
      "proxy_port"=>8080,
      "proxy_type"=>-1,
      "proxy_username"=>"",
      "queueing_enabled"=>false,
      "save_path"=>"/home/jeff/Downloads",
      "scan_dirs"=>[],
      "schedule_from_hour"=>8,
      "schedule_from_min"=>0,
      "schedule_to_hour"=>20,
      "schedule_to_min"=>0,
      "scheduler_days"=>0,
      "scheduler_enabled"=>false,
      "ssl_cert"=>"",
      "ssl_key"=>"",
      "temp_path"=>"/home/jeff/Downloads/temp",
      "temp_path_enabled"=>false,
      "up_limit"=>50,
      "upnp"=>true,
      "use_https"=>false,
      "web_ui_password"=>"ae150cdc82b40c4373d2e15e0ffe8f67",
      "web_ui_port"=>8083,
      "web_ui_username"=>"admin"
    }
  }

  context "#preferences" do

    it "returns hash" do
      client = WebUI.new(test_ip, test_port, test_user, test_pass)
      res = client.preferences

      expect(res.class).to eq Hash
      expect(res['alt_dl_limit']).to_not eq nil
      expect(res['alt_up_limit']).to_not eq nil
      expect(res['save_path']).to_not eq nil
    end
  end

  context "#preferences=" do

    let(:save_path) {
      "/home/jeff/projects/ruby/qbittorrent/tmp/spec/client"
    }

    it "sets preferences when provided a valid hash" do
      client = WebUI.new(test_ip, test_port, test_user, test_pass)
      orig_save_path = client.preferences['save_path']

      res = client.preferences = { "save_path"=>save_path }

      # Read preferences back and verify update
      res = client.preferences
      expect(res["save_path"]).to eq save_path

      # Set the save_path back to original value
      res = client.preferences = { "save_path"=>orig_save_path }
    end

    it "fails when not provided a Hash" do
      client = WebUI.new(test_ip, test_port, test_user, test_pass)
      expect{ client.preferences = "\"save_path\":\"#{save_path}\"" }.to raise_exception
    end
  end

  context "#pause" do

    it "pauses a torrent" do
      hash, name = given_a_downloading_torrent

      client = WebUI.new(test_ip, test_port, test_user, test_pass)
      res = client.pause hash
      # Give app a chance to update
      sleep 2

      data = client.torrent_data hash
      expect(data["state"]).to eq 'pausedDL'
    end
  end

  context "#pause_all" do

    it "pauses all torrents" do
      hash, name = given_a_downloading_torrent
      hash2, name2 = given_another_downloading_torrent

      client = WebUI.new(test_ip, test_port, test_user, test_pass)
      res = client.pause_all
      # Give app a chance to update
      sleep 2

      data = client.torrent_data hash
      #print_response data
      #puts "state: #{data["state"]}"

      data2 = client.torrent_data hash2
      #print_response data2
      #puts "state: #{data2["state"]}"

      expect(data["state"]).to eq 'pausedDL'
      expect(data2["state"]).to eq 'pausedDL'
    end
  end

  context "#resume" do

    it "resumes a paused torrent" do
      hash, name = given_a_paused_downloading_torrent

      client = WebUI.new(test_ip, test_port, test_user, test_pass)
      res = client.resume hash
      # Give app a chance to update
      sleep 2

      data = client.torrent_data hash
      state = data["state"]
      state_is_expected = (state == 'stalledDL' or state == 'downloading')

      expect(state_is_expected).to eq true
    end
  end

  context "#resume_all" do

    it "resumes all paused torrents" do
      hash, name = given_a_paused_downloading_torrent
      hash2, name2 = given_another_paused_downloading_torrent

      client = WebUI.new(test_ip, test_port, test_user, test_pass)
      res = client.resume_all
      # Give app a chance to update
      sleep 2

      data = client.torrent_data hash
      state = data["state"]
      state_is_expected = (state == 'stalledDL' or state == 'downloading')

      expect(state_is_expected).to eq true

      data = client.torrent_data hash2
      state = data["state"]
      state_is_expected = (state == 'stalledDL' or state == 'downloading')

      expect(state_is_expected).to eq true
    end
  end

  context "#download" do

    it "downloads a torrent" do
      client = WebUI.new(test_ip, test_port, test_user, test_pass)

      res = client.download test_torrent_url
      # Give app a chance to update
      sleep 2

      # Verify torrent is downloading
      expect(torrent_with_name_exists?(client, test_torrent_name)).to eq true

      # Pause the download so we don't waste bandwidth
      unless hash.nil?
        client.pause hash
      end
    end
  end

  context "#upload" do

    it "upload a torrent from disk" do
      expect(false).to eq true
    end
  end

  context "#delete_torrent_and_data" do

    it "deletes one or more torrents and their data" do
      hash, name = given_a_paused_downloading_torrent

      client = WebUI.new(test_ip, test_port, test_user, test_pass)

      res = client.delete_torrent_and_data hash
      # Give app a chance to update
      sleep 2

      # Verify torrent has been deleted
      expect(torrent_exists?(client, hash)).to eq false
    end
  end

  context "#delete" do

    it "deletes one or more torrents, but not their data" do
      hash, name = given_a_paused_downloading_torrent

      client = WebUI.new(test_ip, test_port, test_user, test_pass)

      res = client.delete hash
      # Give app a chance to update
      sleep 2

      # Verify torrent has been deleted
      expect(torrent_exists?(client, hash)).to eq false
    end
  end

  context "#recheck" do

    it "rechecks a torrent" do
      hash, name = given_a_downloading_torrent
      # Pause so the download can get going.
      sleep 5

      client = WebUI.new(test_ip, test_port, test_user, test_pass)

      res = client.recheck hash
      # Give app a chance to update
      sleep 2

      data = client.torrent_data hash
      state = data["state"]
      #puts "State: #{data['state']}"
      state_is_expected = (state == 'checkingDL' or state == 'checkingUP')

      expect(state_is_expected).to eq true
    end
  end

  context "#increase_priority" do

    it "increase torrent(s) queue priority(s)" do
      hash, name = given_a_downloading_torrent
      hash2, name2 = given_another_downloading_torrent

      client = WebUI.new(test_ip, test_port, test_user, test_pass)

      # Turn on queueing or priority is always '*'.
      enable_queueing client, true
      sleep 2

      # Get initial priority.
      prio = get_torrent_info client, hash2, 'priority'

      # Increase the priority.
      client.increase_priority hash2
      sleep 2

      # Verify it got better (lower number).
      prio_after_increase = get_torrent_info client, hash2, 'priority'

      # Turn queueing back off.
      enable_queueing client, false

      expect(prio_after_increase < prio).to eq true
    end
  end

  context "#decrease_priority" do

    it "decrease torrent(s) queue priority(s)" do
      hash, name = given_a_downloading_torrent
      hash2, name2 = given_another_downloading_torrent

      client = WebUI.new(test_ip, test_port, test_user, test_pass)

      # Turn on queueing or priority is always '*'.
      enable_queueing client, true
      sleep 2

      # Get initial priority.
      prio = get_torrent_info client, hash, 'priority'

      # Decrease the priority.
      client.decrease_priority hash
      sleep 2

      # Verify it got worse (higher number).
      prio_after_decrease = get_torrent_info client, hash, 'priority'

      # Turn queueing back off.
      enable_queueing client, false

      expect(prio_after_decrease > prio).to eq true
    end
  end

  context "#maximize_priority" do

    it "maximize torrent(s) queue priority(s)" do
      hash, name = given_a_downloading_torrent
      hash2, name2 = given_another_downloading_torrent

      client = WebUI.new(test_ip, test_port, test_user, test_pass)

      # Turn on queueing or priority is always '*'.
      enable_queueing client, true
      sleep 2

      # Get initial priority.
      prio = get_torrent_info client, hash2, 'priority'

      # Maximize the priority.
      client.maximize_priority hash2
      sleep 2

      # Verify it was maximized (priority = 1)
      prio_after_increase = get_torrent_info client, hash2, 'priority'

      # Turn queueing back off.
      enable_queueing client, false

      expect(prio_after_increase == '1').to eq true
    end
  end

  context "#minimize_priority" do

    it "minimize torrent(s) queue priority(s)" do
      hash, name = given_a_downloading_torrent
      hash2, name2 = given_another_downloading_torrent

      client = WebUI.new(test_ip, test_port, test_user, test_pass)

      # Turn on queueing or priority is always '*'.
      enable_queueing client, true
      sleep 2

      # Get initial priority.
      prio = get_torrent_info client, hash, 'priority'

      # Minimize the priority.
      client.minimize_priority hash
      sleep 2

      # Verify it was minimized (priority = 2, because there are only 2 torrents active)
      prio_after_decrease = get_torrent_info client, hash, 'priority'

      # Turn queueing back off.
      enable_queueing client, false

      expect(prio_after_decrease == '2').to eq true
    end
  end

  context "#set_file_priority" do

    it "set a file's priority (within a torrent)" do
      expect(false).to eq true
    end
  end

  context "#global_download_limit" do

    it "return the global download limit" do
      expect(false).to eq true
    end
  end

  context "#global_download_limit=" do

    it "set the global download limit" do
      expect(false).to eq true
    end
  end

  context "#global_upload_limit" do

    it "return the global upload limit" do
      expect(false).to eq true
    end
  end

  context "#global_upload_limit=" do

    it "set the global upload limit" do
      expect(false).to eq true
    end
  end

  context "#download_limit" do

    it "return the torrent download limit" do
      expect(false).to eq true
    end
  end

  context "#download_limit=" do

    it "set the torrent download limit" do
      expect(false).to eq true
    end
  end

  context "#upload_limit" do

    it "return the torrent upload limit" do
      expect(false).to eq true
    end
  end

  context "#upload_limit=" do

    it "set the torrent upload limit" do
      expect(false).to eq true
    end
  end

  context "test" do

    it "tests a torrent" do
      #hash, name = given_a_downloading_torrent


      client = WebUI.new(test_ip, test_port, test_user, test_pass)
      hash = hash_from_torrent_name client, test_torrent_name
      res = client.pause hash
      # Give app a chance to update
      sleep 2

      data = client.torrent_data hash
      print_response data
      #expect(data["state"]).to eq 'pausedDL'
    end
  end
end
