require 'bundler/setup'
Bundler.require :default

require_relative 'lib/demo'
require_relative 'lib/legacy'
require_relative 'lib/message'

require_relative 'lib/loader'
Loader.get :latest

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
    flash = Message[params["error"].to_i]
    erb :index, :locals => { :demo => Demo.new, :flash => flash }
  end

  get '/pastes/:paste' do
    id = Legacy.hash_to_id params["paste"]
    puts id

    DB = Sequel.sqlite("legacy.sqlite") unless defined?(DB)
    paste = DB[:pastes].where(:id => id)

    ver = Loader.latest
    lang = paste.get(:language)
    source = paste.get(:source)

    demo = Demo.new ver, lang, source
    date = paste.get(:created_at).strftime("%b %e, %Y")
    erb :paste, :locals => { :demo => demo, :date => date }
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
      { :ver => demo.version, :source => demo.source, :result => demo.result }.to_json
    else
      halt 400 if params["parse"].nil?
      halt 413 if params["parse"]["source"].length > 1500

      ver = params["parse"]["version"]
      lang = params["parse"]["language"]
      source = params["parse"]["source"]
      halt 400 if ver.nil? || lang.nil? || source.nil?

      source = Base64.urlsafe_encode64 source, padding: false
      redirect to("/" + ver + "/" + lang + "/" + source)
    end
  end

  get '/:ver/:lang/:source?' do
    halt 400 unless params["ver"][0] == "v"

    if params["source"].nil? || params["source"] == "draft"
      demo = Demo.new params["ver"], params["lang"] rescue halt 400
      erb :index, :locals => { :demo => demo, :flash => nil }
    else
      halt 413 if params["source"].length > 1500
      source = Base64.urlsafe_decode64 params["source"]
      demo = Demo.new params["ver"], params["lang"], source rescue halt 400
      erb :index, :locals => { :demo => demo, :flash => nil }
    end
  end

  error 400..500 do
    case request.content_type
    when "application/json"
      content_type :json
      { :message => Message[response.status] }.to_json
    else
      redirect to("/?error=" + response.status.to_s)
    end
  end
end
