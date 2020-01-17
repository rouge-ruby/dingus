require 'rouge'
require 'sinatra/base'

class Dingus < Sinatra::Base
  get '/' do
    erb :index
  end
end
