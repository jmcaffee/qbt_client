require 'spec_helper'
include TorrentProcessor::Service::Qbittorrent

def tdata hash, name
  data = %w(hash 1 name 100 100 100 100 1000 10 20 1h TV 5 10 1 Y 1 0 unk1 unk2 message unk4 unk5 unk6 unk7 folder unk8)
  data[0] = hash
  data[2] = name
  TorrentProcessor::Service::UTorrent::TorrentData.new data
end

#describe TorrentProcessor::Service::Qbittorrent::QbtClient do
describe QbtClient do

  let(:tmp_path) do
    spec_tmp_dir('qbt_client')
  end

  let(:client_stub) do
    obj = QbtClient.new('127.0.0.1', '8083', 'admin', 'abc')
    #obj.filepath = 'memory'
    #obj
  end

  let(:init_args) do
    {
      :cfg => cfg_stub,
      #:verbose => true, # Default: false
      :logger => ::ScreenLogger,
    }
  end

  let(:cfg_stub) do
    cfg = TorrentProcessor.configuration

    cfg.app_path          = tmp_path
    cfg.logging           = false
    cfg.max_log_size      = 0
    cfg.log_dir           = tmp_path
    cfg.tv_processing     = File.join(tmp_path, 'media/tv')
    cfg.movie_processing  = File.join(tmp_path, 'media/movies')
    cfg.other_processing  = File.join(tmp_path, 'media/other')
    cfg.filters           = {}

    cfg.utorrent.ip                     = '127.0.0.1'
    cfg.utorrent.port                   = '8083'
    cfg.utorrent.user                   = 'admin'
    cfg.utorrent.pass                   = 'abc'
    cfg.utorrent.dir_completed_download = File.join(tmp_path, 'torrents/completed')
    cfg.utorrent.seed_ratio             = 0

    cfg.tmdb.api_key              = '94e9baf013926749c7ab79481d1786b2'
    cfg.tmdb.language             = 'en'
    cfg.tmdb.target_movies_path   = File.join(tmp_path, 'movies_final')
    cfg.tmdb.can_copy_start_time  = "00:00"
    cfg.tmdb.can_copy_stop_time   = "23:59"
    cfg
  end

  context "#connect" do

    let(:ip) { 'http://127.0.0.1' }
    let(:port) { 8083 }
    let(:user) { 'admin' }
    let(:pass) { 'abc' }

    it "returns 200 on successful connection" do
      client = QbtClient.new(ip, port, user, pass)
      expect(client.connect).to eq 200
    end

    it "returns 401 on failed connection" do
      client = QbtClient.new(ip, port, user, 'badpass')
      expect(client.connect).to eq 401
    end
  end
end
