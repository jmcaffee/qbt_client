# QbtClient

A Ruby gem to access qBittorrent's [WebUI](https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-Documentation)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'qbt_client'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install qbt_client

## Usage

Instantiate the client

```ruby
require 'qtb_client'

ip   = 'http://127.0.0.1' # Protocol is required.
port = 8083
user = 'admin'
pass = 'abc'

client = QtbClient::WebUI.new(ip, port, user, pass)
```

Call methods on the client

```ruby
# Get list of torrents:
torrents = client.torrent_list


torrent_properties = {}

# Using each torrent's hash, get the torrents properties:
torrents.each do |t|
  hash = t['hash']

  torrent_properties[hash] = client.properties hash

  # Get the torrent's trackers too
  torrent_properties[hash]['trackers'] = client.trackers hash
end
```

The `WebUI` class is well documented with the expected input/output for the API calls.

## qBitTorrent/WebUI API Versions

Due to breaking changes, if you're using qBitTorrent v3.1.x or older, use version `~> 0.1` (v0.1.0+) of this gem.

qBitTorrent v3.2.x uses v2 of the WebUI API and should use version `~> 1` (v1.0.0+) of this gem.

See the CHANGELOG.txt for more details of what has changed.

## Bugs/Questions/Get Help

Create an issue at [https://github.com/jmcaffee/qbt_client/issues](https://github.com/jmcaffee/qbt_client/issues).

## Testing

To run the tests, you'll need to have qBittorrent installed locally, WebUI
turned on, and the credentials set to:

- user: admin
- pass: abc

The tests assume that qBittorrent is running at 127.0.0.1, port 8083.

From the root project dir, run:

    $ rspec spec/

## Contributing

1. Fork it ( https://github.com/[my-github-username]/qbt_client/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Create your tests
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create a new Pull Request

