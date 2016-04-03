$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'qbt_client'
require 'digest'

def print_response res
  puts 'response:'
  puts res.inspect
end

def test_ip
  'http://127.0.0.1'
end

def test_port
  8083
end

def test_user
  'admin'
end

def test_pass
  'abcabc'
end

def test_torrent_url
  "http://www.slackware.com/torrents/slackware64-14.1-install-dvd.torrent"
end

def test_torrent_name
  "slackware64-14.1-iso"
end

def test_torrent_url2
  "http://torrent.unix-ag.uni-kl.de/torrents/KNOPPIX_V7.4.2DVD-2014-09-28-EN.torrent"
end

def test_torrent_name2
  "KNOPPIX_V7.4.2DVD-2014-09-28-EN"
end

def get_torrent_info client, torrent_hash, key
  info = {}
  client.torrent_list.each do |t|
    if t["hash"] == torrent_hash
      info = t
    end
  end
  info[key]
end

def hash_from_torrent_name client, name
  torrents = client.torrent_list
  hash = nil

  torrents.each do |t|
    if t["name"] == name
      hash = t["hash"]
    end
  end
  hash
end

def delete_torrent_with_hash client, hash
  unless hash.nil? or hash.empty?
    client.delete_torrent_and_data hash
  end
end

def delete_torrent_with_name client, name
  unless name.nil? or name.empty?
    hash = hash_from_torrent_name client, name
    delete_torrent_with_hash client, hash
  end
end

def download_torrent name, url
  client = QbtClient::WebUI.new(test_ip, test_port, test_user, test_pass)

  # If we're already downloading the torrent, delete it
  delete_torrent_with_name client, name

  # Start the download...
  client.download url
  sleep 2

  hash = hash_from_torrent_name client, name

  # Return the info.
  [hash, name]
end

def download_and_pause_torrent name, url
  client = QbtClient::WebUI.new(test_ip, test_port, test_user, test_pass)

  # If we're already downloading the torrent, just pause it and return its data
  hash = hash_from_torrent_name client, name
  unless hash.nil?
    client.pause hash
    return [hash, name]
  end

  # Torrent not found, start the download...
  client.download url
  sleep 2

  hash = hash_from_torrent_name client, name

  # Pause the download...
  client.pause hash

  # Return the info.
  [hash, name]
end

def given_a_downloading_torrent
  download_torrent test_torrent_name, test_torrent_url
end

def given_another_downloading_torrent
  download_torrent test_torrent_name2, test_torrent_url2
end

def given_a_paused_downloading_torrent
  download_and_pause_torrent test_torrent_name, test_torrent_url
end

def given_another_paused_downloading_torrent
  download_and_pause_torrent test_torrent_name2, test_torrent_url2
end

def torrent_exists? client, hash
  return false if (client.properties(hash)).nil?
  true
end

def torrent_with_name_exists? client, name
  hash = hash_from_torrent_name client, name

  return false if (client.properties(hash)).nil?
  true
end

def md5 str
  Digest::MD5.hexdigest str
end

def enable_queueing client, enable
  client.set_preferences({ "queueing_enabled" => enable })
end

def queueing_enabled? client
  prefs = client.preferences
  prefs['queueing_enabled']
end

def delete_all_torrents
  client = QbtClient::WebUI.new(test_ip, test_port, test_user, test_pass)
  torrents = client.torrent_list
  hash = nil

  torrents.each do |t|
    client.delete_torrent_and_data t["hash"]
  end
end

