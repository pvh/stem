require 'sinatra'
require 'json'
require 'lib/greenfield'

module GreenField
  class HerokuApi < Sinatra::Base
    post "/resources" do
      params       = JSON.parse(request.body.string)
      id           = params["heroku_id"]
      plan         = params["plan"]
      callback_url = params["callback_url"]

      config = JSON.parse( File.read("postgres-server/config.json") )
      userdata = File.read("postgres-server/userdata.sh")

      ip = GreenField.allocate_ip
      instance = GreenField.create(config, userdata)

      while GreenField.inspect(instance)["instanceState"]["name"] != "running"
        sleep 1
      end

      GreenField.associate_ip(ip, instance)

      {:id => id, :config => {"GREENFIELD_URL" => "http://#{ip}"}}.to_json
    end

    delete "/resources/:name" do |name|
      @server = @bifrost.server(name)
      @bifrost.destroy_server_async(name)
      "ok"
    end

  end
end

