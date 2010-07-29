require 'sinatra'
require 'json'
require 'lib/stem'
require 'mustache'

module Stem
  class HerokuApi < Sinatra::Base
    post "/resources" do
      params       = JSON.parse(request.body.string)
      id           = params["heroku_id"]
      plan         = params["plan"]
      callback_url = params["callback_url"]

      config = JSON.parse( File.read("postgres-server/config.json") )
      template = File.read("postgres-server/userdata.sh.mustache")
      data = {
        "db_role" => (10 + rand(26)).to_s(36) + rand(2**64).to_s(36),
        "db_password" => rand(2**128).to_s(36),
        "pg_admin_password" => rand(2**128).to_s(36)
      }
      userdata = Mustache.render(template, data)

      puts "Allocating an IP"
      ip = Stem.allocate_ip
      instance = Stem.create(config, userdata)

      while true
        i = Stem.inspect(instance)
        break if i["instanceState"]["name"] == "running"
        sleep 1
        puts "Waiting... #{ i["instanceState"]["name"] }"
      end

      Stem.associate_ip(ip, instance)

      {:id => id, :config => {"STEM_URL" =>
        "postgres://#{data["db_role"]}:#{data["db_password"]}#{ip}/#{data["db_role"]}"}}.to_json
    end

    delete "/resources/:name" do |name|
      @server = @sample.server(name)
      @sample.destroy_server_async(name)
      "ok"
    end

  end
end

