require 'base64'
require 'json'
require 'rouge'
require 'sassc'
require 'sinatra/base'
require 'sprockets'
require 'uglifier'

class Demo
  attr_reader :lexer, :source

  def initialize(lang = nil, source = nil)
    @lexer = set_lexer lang
    @source = set_source source
  end

  def all_lexers
    Rouge::Lexer.all.sort_by(&:tag)
  end

  def lexer_count
    all_lexers.count
  end

  def result
    Rouge.highlight source, lexer, 'html'
  end

  def version
    Rouge.version
  end

  private def set_lexer(lang)
    return all_lexers.sample if lang.nil?

    Rouge::Lexer.find(lang) || all_lexers.sample
  end

  private def set_source(source)
    source || lexer.demo
  end
end

class Dingus < Sinatra::Base
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
    erb :index, :locals => { :demo => Demo.new }
  end

  post '/parse' do
    case request.content_type
    when "application/json"
      halt 413 if request.content_length.to_i > 2000

      payload = JSON.parse request.body.read
      halt unless payload["lang"]

      demo = Demo.new payload["lang"], payload["source"]
      content_type :json
      { :source => demo.source, :result => demo.result }.to_json
    else
      halt 400 if params["parse"].nil?
      halt 413 if params["parse"]["source"].length > 1500

      lang = params["parse"]["language"]
      source = params["parse"]["source"]
      halt 400 if lang.nil? || source.nil?

      source = Base64.urlsafe_encode64 source, padding: false
      redirect to("/" + lang + "/" + source)
    end
  end

  get '/:lang/:source?' do
    if params["source"].nil? || params["source"] == "draft"
      erb :index, :locals => { :demo => Demo.new(params["lang"]) }
    else
      halt 413 if params["source"].length > 1500

      puts params["source"].inspect

      source = Base64.urlsafe_decode64 params["source"]
      erb :index, :locals => { :demo => Demo.new(params["lang"], source) }
    end
  end
end
