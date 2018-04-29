require 'spec_helper'
require 'steam_id_filter'

describe SteamIdFilter do
  describe 'to_id64' do
    it 'returns a steamid64 when called with a steamid64 as an integer' do
      expect(SteamIdFilter.to_id64(76561198127904574)).to eq 76561198127904574
    end

    it 'returns a steamid64 when called with a steamid64 as a string' do
      expect(SteamIdFilter.to_id64('76561198127904574')).to eq 76561198127904574
    end

    it 'returns a steamid64 when called with a steamid2' do
      expect(SteamIdFilter.to_id64('STEAM_0:0:83819423')).to eq 76561198127904574
    end

    it 'returns a steamid64 when called with a steamid3' do
      expect(SteamIdFilter.to_id64('[U:1:167638846]')).to eq 76561198127904574
    end

    it 'returns a steamid64 when called with a custom url' do
      expect(SteamIdFilter.to_id64('steamcommunity.com/id/mr64bit')).to eq 76561198127904574
    end

    it 'returns a steamid64 when called with just the custom part of the url' do
      expect(SteamIdFilter.to_id64('mr64bit')).to eq 76561198127904574
    end

    it 'returns nil when no match is found' do
      expect(SteamIdFilter.to_id64('hello world')).to eq nil
    end
  end
end
