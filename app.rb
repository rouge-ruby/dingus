require 'base64'
require 'json'
require 'sassc'
require 'sinatra/base'
require 'sprockets'
require 'uglifier'

require_relative 'lib/loader'

Loader.get :latest

class Demo
  attr_reader :rouge, :lexer, :source

  def initialize(ver = :latest, lang = nil, source = nil)
    @rouge = set_version ver
    @lexer = set_lexer lang
    @source = set_source source
  end

  def all_lexers
    rouge::Lexer.all.sort_by(&:tag)
  end

  def lexer_count
    all_lexers.count
  end

  def result
    rouge.highlight source, lexer, 'html'
  end

  def version
    rouge.version
  end

  private def set_version(ver)
    ver = (ver.is_a?(String) && ver[0] == "v") ? ver.slice(1..-1) : :latest

    Loader.get ver
  end

  private def set_lexer(lang)
    return all_lexers.sample if lang.nil?

    rouge::Lexer.find(lang) || all_lexers.sample
  end

  private def set_source(source)
    source || lexer.demo
  end
end

class Message
  MSG = {}

  MSG[400] =
    "<strong>Bad Input</strong>: The input that you submitted is invalid. Please
    correct it and try again."

  MSG[413] =
    "<strong>Too Long</strong>: This form accepts a maximum of 1500 characters of text.
    Please reduce the amount of text and try again."

  def self.[](k)
    MSG[k]
  end
end

class Dingus < Sinatra::Base
  enable :sessions

  # initialize new sprockets environment
  set :environment, Sprockets::Environment.new

  # append assets paths
  environment.append_path "assets/images"
  environment.append_path "assets/stylesheets"
  environment.append_path "assets/javascripts"

  # compress assets
  environment.js_compressor  = Uglifier.new(harmony: true)
  environment.css_compressor = :scssc

  # get assets
  get "/assets/*" do
    env["PATH_INFO"].sub!("/assets", "")
    settings.environment.call(env)
  end

  get '/' do
    flash = Message[session[:error]]
    session[:error] = nil
    erb :index, :locals => { :demo => Demo.new, :flash => flash }
  end

  post '/parse' do
    case request.content_type
    when "application/json"
      halt 413 if request.content_length.to_i > 2000

      payload = JSON.parse request.body.read
      halt 400 unless payload["ver"] && payload["lang"]

      demo = Demo.new payload["ver"],
                      payload["lang"],
                      payload["source"] rescue halt 400
      content_type :json
      { :source => demo.source, :result => demo.result }.to_json
    else
      halt 400 if params["parse"].nil?
      halt 413 if params["parse"]["source"].length > 1500

      ver = params["parse"]["version"]
      lang = params["parse"]["language"]
      source = params["parse"]["source"]
      halt 400 if ver.nil? || lang.nil? || source.nil?

      source = Base64.urlsafe_encode64 source, padding: false
      redirect to("/" + lang + "/" + source)
    end
  end

  get '/:ver/:lang/:source?' do
    halt 400 unless params["ver"][0] == "v"

    if params["source"].nil? || params["source"] == "draft"
      demo = Demo.new params["ver"], params["lang"] rescue halt 400
      erb :index, :locals => { :demo => demo }
    else
      halt 413 if params["source"].length > 1500
      source = Base64.urlsafe_decode64 params["source"]
      demo = Demo.new params["ver"], params["lang"], source rescue halt 400
      erb :index, :locals => { :demo => demo }
    end
  end

  error 400..500 do
    case request.content_type
    when "application/json"
      content_type :json
      { :message => Message[response.status] }.to_json
    else
      session[:error] = response.status
      redirect to("/")
    end
  end
end
