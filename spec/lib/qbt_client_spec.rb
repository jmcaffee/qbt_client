require 'spec_helper'

describe QbtClient do
  it 'has a version number' do
    expect(QbtClient::VERSION).not_to be nil
  end

  it 'returns the web client api version' do
    client = QbtClient::WebUI.new(test_ip, test_port, test_user, test_pass)
    expect(client.api_version).to eq("2")
  end

  it 'returns the web client minimum api version' do
    client = QbtClient::WebUI.new(test_ip, test_port, test_user, test_pass)
    expect(client.api_min_version).to eq("2")
  end

  it 'returns the app (qbttorrent) version' do
    client = QbtClient::WebUI.new(test_ip, test_port, test_user, test_pass)
    expect(client.app_version).to eq("v3.2.0")
  end
end
