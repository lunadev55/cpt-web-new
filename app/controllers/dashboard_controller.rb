class DashboardController < ApplicationController
    before_action :require_user
    require 'net/http'
    require 'net/https'
    def index
    end
end
