class SteamIdFilter
  VALID_LENGTH = 76561197960265728
  def self.to_id64(input)
    begin
      if self.valid_steamid64(input)
        return input
      elsif self.valid_steamid64(input.to_i)
        return input.to_i
      elsif input.class == String
        if input =~ /^STEAM_[0-1]:([0-1]:[0-9]+)$/
          output = $1.split(':').map! { |s| s.to_i }
          return output[0] + output[1] * 2 + 76561197960265728
        elsif input =~ /^\[U:([0-1]:[0-9]+)\]$/
          output = $1.split(':').map { |s| s.to_i }
          return output[0] + output[1] + 76561197960265727
        elsif input =~ /id\/(.+)$/i
          return SteamCondenser::Community::SteamId.new($1).steam_id64
        else
          return SteamCondenser::Community::SteamId.new(input).steam_id64
        end
      else
      end
    rescue
      return nil
    end
  end

  def self.valid_steamid64(input)
    return input.class == Fixnum && input > VALID_LENGTH
  end
end
