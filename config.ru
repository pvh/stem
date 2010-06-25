require 'web'

map "/heroku" do
  run GreenField::HerokuApi
end
