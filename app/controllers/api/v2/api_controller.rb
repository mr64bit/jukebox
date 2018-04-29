module Api_v2
  require('rocket_pants')
  class Api::V2::ApiController < RocketPants::Base
    before_action :authenticate

    private

    def authenticate
      request_http_basic_authentication unless authenticate_with_http_basic { |name, password| auth_type(name, password) }
    end

    def auth_type(name, password)
      if Digest::SHA1.hexdigest(password) == Settings::ApiKeys[name]
        @authed = true
        @auth_type = name
        # Rails.logger.debug "Authentication succesful, #{name}:#{password}"
      else
        @authed = false
        @auth_type = nil
        # Rails.logger.debug "Authentication failed, #{name}:#{password}"
      end
      return @authed
    end
  end
end
