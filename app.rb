require 'cgi'
require 'json'
require 'rouge'
require 'sinatra/base'
require 'sprockets'
require 'uglifier'
require 'sassc'

require_relative "lib/coder"

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
    halt 413 if request.content_length.to_i > 2000

    payload = JSON.parse request.body.read
    halt unless payload["lang"]

    demo = Demo.new payload["lang"], payload["source"]
    content_type :json
    { :source => demo.source, :result => demo.result }.to_json
  end

  get '/:lang/:source' do
    lang = CGI.unescape params["lang"]
    source = Coder.decode CGI.unescape(params["source"])
    erb :index, :locals => { :demo => Demo.new(lang, source) }
  end
end
