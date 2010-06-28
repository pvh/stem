require 'web'

map "/heroku" do
  run Stem::HerokuApi
end
