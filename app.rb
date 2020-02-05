require 'bundler/setup'
Bundler.require :default

require_relative 'lib/demo'
require_relative 'lib/legacy'
require_relative 'lib/message'

require_relative 'lib/loader'
Loader.get :latest

class Dingus < Sinatra::Base
  # Set maximum sizes
  MAX_PATH_SIZE = 1900
  MAX_BODY_SIZE = 1400

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

  before do
    halt 413 if request.path.length > MAX_PATH_SIZE ||
                request.content_length.to_i > MAX_BODY_SIZE
  end

  get '/' do
    flash = Message[params["error"].to_i]
    erb :index, :locals => { :demo => Demo.new, :flash => flash }
  end

  get '/message/:code' do
    content_type :json
    { :message => Message[params["code"].to_i] }.to_json
  end

  post '/parse' do
    case request.content_type
    when "application/json"
      payload = JSON.parse request.body.read

      demo = Demo.new payload["ver"],
                      payload["lang"],
                      payload["source"] rescue halt 400

      content_type :json
      { :ver => demo.version, :source => demo.source, :result => demo.result }.to_json
    else
      halt 400 if params["parse"].nil?

      ver = params["parse"]["version"]
      lang = params["parse"]["language"]
      source = params["parse"]["source"]
      halt 400 if ver.nil? || lang.nil? || source.nil?

      source = Base64.urlsafe_encode64 source, padding: false
      redirect to("/" + ver + "/" + lang + "/" + source)
    end
  end

  get '/pastes/:id' do
    paste = Legacy.paste params["id"]
    halt 400 unless paste

    ver = "v" + Loader.latest
    lang = paste[:language]
    source = paste[:source]

    demo = Demo.new ver, lang, source
    date = paste[:created_at].strftime("%b %e, %Y")
    erb :paste, :locals => { :demo => demo, :date => date }
  end

  get '/:ver/:lang/:source?' do
    if params["source"].nil? || params["source"] == "draft"
      demo = Demo.new params["ver"], params["lang"] rescue halt 400
    else
      source = Base64.urlsafe_decode64(params["source"]).force_encoding("utf-8")
      demo = Demo.new params["ver"], params["lang"], source rescue halt 400
    end

    erb :index, :locals => { :demo => demo, :flash => nil }
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
