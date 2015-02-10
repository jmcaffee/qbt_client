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

client = QtbClient::Client.new(ip, port, user, pass)
```

Call methods on the client

```ruby
# Get list of torrents:
torrents = client.torrent_list

# Using each torrent's hash, get more data about the torrent:
torrent_data = []
torrents.each do |t|
  torrent_data << client.torrent_data t['hash']
end
```

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

