require 'spec_helper'
include QbtClient

describe WebUI do

  after(:all) do
    delete_all_torrents
    sleep 1
  end

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

  context "#properties" do

    it "returns torrent properties in Hash object" do
      hash, name = given_a_paused_downloading_torrent
      sleep 1

      client = WebUI.new(test_ip, test_port, test_user, test_pass)
      res = client.properties hash

      expect(res.class).to eq Hash
      expect(res['save_path']).to_not eq nil
    end
  end

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

    it "add one tracker to a torrent" do
      hash, name = given_a_paused_downloading_torrent

      client = WebUI.new(test_ip, test_port, test_user, test_pass)
      trackers = client.trackers hash
      tcount = trackers.count

      url = 'http://announce.tracker.com'

      client.add_trackers hash, url
      sleep 2

      trackers = client.trackers hash
      expect(trackers.count).to eq (tcount + 1)

      expect(trackers[tcount]['url']).to eq url
    end

    it "add multiple trackers to a torrent" do
      hash, name = given_a_paused_downloading_torrent

      client = WebUI.new(test_ip, test_port, test_user, test_pass)
      trackers = client.trackers hash
      tcount = trackers.count

      url1 = 'http://announce.tracker.com:1000'
      url2 = 'http://announce.tracker.com:2000'
      url3 = 'http://announce.tracker.com:3000'

      client.add_trackers hash, [url1, url2, url3]
      sleep 2

      trackers = client.trackers hash
      expect(trackers.count).to eq (tcount + 3)

      expect(trackers[tcount]['url']).to eq url1
      expect(trackers[tcount+1]['url']).to eq url2
      expect(trackers[tcount+2]['url']).to eq url3
    end

    it "ampersands in tracker urls are escaped" do
      hash, name = given_a_paused_downloading_torrent

      client = WebUI.new(test_ip, test_port, test_user, test_pass)
      trackers = client.trackers hash
      tcount = trackers.count

      url1 = 'http://announce.tracker.com:1000?blah&blah'
      url2 = 'http://announce.tracker.com:2000?foo&foo'
      url3 = 'http://announce.tracker.com:3000?bar&bar'

      client.add_trackers hash, [url1, url2, url3]
      sleep 2

      trackers = client.trackers hash
      expect(trackers.count).to eq (tcount + 3)

      expect(trackers[tcount]['url']).to eq url1
      expect(trackers[tcount+1]['url']).to eq url2
      expect(trackers[tcount+2]['url']).to eq url3
    end
  end

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

  context "#set_preferences" do

    let(:save_path) {
      "/home/jeff/projects/ruby/qbittorrent/tmp/spec/client"
    }

    it "sets preferences when provided a valid hash" do
      client = WebUI.new(test_ip, test_port, test_user, test_pass)
      orig_save_path = client.preferences['save_path']

      res = client.set_preferences({ "save_path"=>save_path })

      # Read preferences back and verify update
      res = client.preferences
      expect(res["save_path"]).to eq save_path

      # Set the save_path back to original value
      res = client.set_preferences({ "save_path"=>orig_save_path })
    end

    it "fails when not provided a Hash" do
      client = WebUI.new(test_ip, test_port, test_user, test_pass)
      expect{ client.set_preferences("\"save_path\":\"#{save_path}\"") }.to raise_exception
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
      pending('implementation')
      fail
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
      hash, name = given_a_paused_downloading_torrent
      client = WebUI.new(test_ip, test_port, test_user, test_pass)
      files = client.contents hash

      # Set priority for each file in torrent.
      # Priority will equal its position +1.
      files.each_with_index do |f,i|
        client.set_file_priority hash, i, (i+1)
      end
      sleep 2

      # Verify each file's priority matches its position +1
      files = client.contents hash
      files.each_with_index do |f,i|
        prio = i + 1
        expect( f['priority'] == prio ).to eq true
      end

      # Clean up
      client.delete_torrent_and_data hash
    end
  end

  context "#global_download_limit" do

    it "return the global download limit in bytes" do
      hash, name = given_a_paused_downloading_torrent
      client = WebUI.new(test_ip, test_port, test_user, test_pass)
      limit = client.global_download_limit

      expect(limit.integer?).to eq true
    end
  end

  context "#set_global_download_limit" do

    it "set the global download limit in bytes" do
      hash, name = given_a_paused_downloading_torrent
      client = WebUI.new(test_ip, test_port, test_user, test_pass)
      old_limit = client.global_download_limit

      expected_limit = 1000
      client.set_global_download_limit expected_limit

      actual_limit = client.global_download_limit

      expect(expected_limit == actual_limit).to eq true

      # Clean up
      client.set_global_download_limit old_limit
    end
  end

  context "#global_upload_limit" do

    it "return the global upload limit in bytes" do
      hash, name = given_a_paused_downloading_torrent
      client = WebUI.new(test_ip, test_port, test_user, test_pass)
      limit = client.global_upload_limit

      expect(limit.integer?).to eq true
    end
  end

  context "#set_global_upload_limit" do

    it "set the global upload limit in bytes" do
      hash, name = given_a_paused_downloading_torrent
      client = WebUI.new(test_ip, test_port, test_user, test_pass)
      old_limit = client.global_upload_limit

      expected_limit = 1000
      client.set_global_upload_limit expected_limit

      actual_limit = client.global_upload_limit

      expect(expected_limit == actual_limit).to eq true

      # Clean up
      client.set_global_upload_limit old_limit
    end
  end

  context "#download_limit" do

    it "return the torrent download limit in bytes" do
      hash, name = given_a_paused_downloading_torrent
      client = WebUI.new(test_ip, test_port, test_user, test_pass)
      limit = client.download_limit hash

      expect(limit.integer?).to eq true
    end
  end

  context "#set_download_limit" do

    it "set the torrent download limit in bytes" do
      hash, name = given_a_paused_downloading_torrent
      client = WebUI.new(test_ip, test_port, test_user, test_pass)
      old_limit = client.download_limit hash

      expected_limit = 1000
      client.set_download_limit hash, expected_limit

      actual_limit = client.download_limit hash

      expect(expected_limit == actual_limit).to eq true

      # Clean up
      client.set_download_limit hash, old_limit
    end
  end

  context "#upload_limit" do

    it "return the torrent upload limit in bytes" do
      hash, name = given_a_paused_downloading_torrent
      client = WebUI.new(test_ip, test_port, test_user, test_pass)
      limit = client.upload_limit hash

      expect(limit.integer?).to eq true
    end
  end

  context "#set_upload_limit" do

    it "set the torrent upload limit in bytes" do
      hash, name = given_a_paused_downloading_torrent
      client = WebUI.new(test_ip, test_port, test_user, test_pass)
      old_limit = client.upload_limit hash

      expected_limit = 1000
      client.set_upload_limit hash, expected_limit

      actual_limit = client.upload_limit hash

      expect(expected_limit == actual_limit).to eq true

      # Clean up
      client.set_upload_limit hash, old_limit
    end
  end

  #context "test" do

  #  it "tests a torrent" do
  #    #hash, name = given_a_downloading_torrent


  #    client = WebUI.new(test_ip, test_port, test_user, test_pass)
  #    hash = hash_from_torrent_name client, test_torrent_name
  #    res = client.pause hash
  #    # Give app a chance to update
  #    sleep 2

  #    data = client.torrent_data hash
  #    print_response data
  #    #expect(data["state"]).to eq 'pausedDL'
  #  end
  #end
end
