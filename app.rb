# frozen_string_literal: true

require 'bundler/setup'
Bundler.require :default

require_relative 'lib/demo'
require_relative 'lib/message'

require_relative 'lib/loader'
Loader.get :latest

class Dingus < Sinatra::Base
  # Set maximum sizes
  MAX_PATH_SIZE = 1900
  MAX_BODY_SIZE = 1400

  enable :logging

  def make_demo(*args)
    Demo.new(*args)
  rescue StandardError => e
    request.logger.error "#{e.message}:\n#{e.backtrace.join("\n")}"
    halt 400
  end

  before do
    halt 413 if request.path.length > MAX_PATH_SIZE ||
                request.content_length.to_i > MAX_BODY_SIZE
  end

  get '/' do
    flash = Message[params['error'].to_i]
    erb :index, locals: { demo: Demo.new, flash: flash }
  end

  get '/message/:code' do
    content_type :json
    { message: Message[params['code'].to_i] }.to_json
  end

  post '/parse' do
    case request.content_type
    when 'application/json'
      payload = JSON.parse request.body.read

      demo = make_demo(payload['ver'], payload['lang'], payload['source'])

      content_type :json

      {
        ver: demo.version,
        display_ver: demo.display_version,
        source: demo.source,
        result: demo.result,
      }.to_json
    else
      halt 400 if params['parse'].nil?

      ver = params['parse']['version']
      lang = params['parse']['language']
      source = params['parse']['source']
      halt 400 if ver.nil? || lang.nil? || source.nil?

      source = Base64.urlsafe_encode64 source, padding: false
      redirect to("/#{ver}/#{lang}/#{source}")
    end
  end

  get '/:ver' do
    demo = make_demo(params['ver'], nil, nil)

    erb :index, locals: { demo: demo, flash: nil }
  end

  get '/:ver/:lang/:source?' do
    demo = if params['source'].nil? || params['source'] == 'draft'
      make_demo(params['ver'], params['lang'])
    else
      source = Base64.urlsafe_decode64(params['source']).force_encoding('utf-8')
      make_demo(params['ver'], params['lang'], source)
    end

    erb :index, locals: { demo: demo, flash: nil }
  end

  # redirect paths ending in /
  get %r(.*/) do
    redirect to(env['PATH_INFO'].chomp('/'))
  end

  error 400..500 do
    case request.content_type
    when 'application/json'
      content_type :json
      { message: Message[response.status] }.to_json
    else
      redirect to("/?error=#{response.status}")
    end
  end
end
