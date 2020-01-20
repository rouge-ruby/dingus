require 'rouge'
require 'sinatra/base'
require 'sprockets'
require 'uglifier'
require 'sassc'

class Demo
  attr_reader :lexer

  def initialize(lang = nil)
    @lexer = select_lexer lang
  end

  def all_lexers
    Rouge::Lexer.all.sort_by(&:tag)
  end

  def lexer_count
    all_lexers.count
  end

  def parsed(text = nil)
    text = source if text.nil?
    Rouge.highlight text, lexer, 'html'
  end

  def select_lexer(lang)
    return all_lexers.sample if lang.nil?

    Rouge::Lexer.find(lang) || all_lexers.sample
  end

  def source
    lexer.demo
  end

  def version
    Rouge.version
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
  environment.js_compressor  = :uglify
  environment.css_compressor = :scssc

  # get assets
  get "/assets/*" do
    env["PATH_INFO"].sub!("/assets", "")
    settings.environment.call(env)
  end

  get '/' do
    erb :index, :locals => { :demo => Demo.new }
  end
end
