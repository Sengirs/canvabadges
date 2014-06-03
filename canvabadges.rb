require 'sinatra/base'
require 'oauth'
require 'json'
require 'dm-core'
require 'dm-migrations'
require 'nokogiri'
require 'oauth/request_proxy/rack_request'
require 'ims/lti'
require 'digest/md5'
require 'net/http'
require 'rack/iframe'

require './lib/models.rb'
require './lib/auth.rb'
require './lib/api.rb'
require './lib/badge_configuration.rb'
require './lib/views.rb'
require './lib/utils.rb'
require './lib/domain_fudger.rb'

class Canvabadges < Sinatra::Base
  register Sinatra::Auth
  register Sinatra::Api
  register Sinatra::BadgeConfiguration
  register Sinatra::Views

  use Rack::Iframe
  use DomainFudger
  
  # sinatra wants to set x-frame-options by default, disable it
  disable :protection
  # enable sessions so we can remember the launch info between http requests, as
  # the user takes the assessment
  enable :sessions
  enable :logging, :dump_errors, :raise_errors, :show_exceptions
  FileUtils.mkdir_p 'log' unless File.exists?('log')
  log = File.new("log/sinatra.log", "a")
  $stderr.reopen(log)

  if ENV["RACK_ENV"] == 'production'
    config = YAML.load( File.open(Dir.pwd + "/configuration.yml") )
    config.each do |key, value|
      ENV[key] = value
    end
    raise "Please change configuration.yml" if ENV['SESSION_KEY'] == "long string" 
    raise "session key required" unless ENV["SESSION_KEY"] 
  end

  set :session_secret, ENV['SESSION_KEY'] || "local_secret"
  env = ENV['RACK_ENV'] || settings.environment
  DataMapper.setup(:default, (ENV["DATABASE_URL"] || "sqlite3:///#{Dir.pwd}/#{env}.sqlite3"))
  DataMapper.auto_upgrade!
  configure :production do
    require 'rack-ssl-enforcer'
    use Rack::SslEnforcer
  end
end

module BadgeHelper
  def self.protocol
    ENV['RACK_ENV'].to_s == "development" ? "http" : "https"
  end
  def self.issuer
    @issuer ||= YAML.load(File.read('./issuer.yml'))
  end
end

