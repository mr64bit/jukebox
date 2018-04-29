module Api_v1
  class Api::V1::ApiController < ApplicationController
    skip_before_filter :verify_authenticity_token
  end
end
