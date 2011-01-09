module Stem
  module Util
    def swirl
      account = "default"
      etc = "#{ENV["HOME"]}/.swirl"
      config = \
      if ENV["AWS_ACCESS_KEY_ID"] && ENV["AWS_SECRET_ACCESS_KEY"]
        {
          :aws_access_key_id => ENV["AWS_ACCESS_KEY_ID"],
          :aws_secret_access_key => ENV["AWS_SECRET_ACCESS_KEY"],
          :version => "2010-08-31"
        }
      else
        account = account.to_sym
        
        if File.exists?(etc)
          data = YAML.load_file(etc)
        else
          abort("I was expecting to find a .swirl file in your home directory.")
        end
        
        if data.key?(account)
          data[account]
        else
          abort("I don't see the account you're looking for")
        end
      end

      @swirl = Swirl::EC2.new config
    end

    def tags_to_filter(tags)
      if tags.is_a? Hash
        tags = tags.inject({}) do |h, (k, v)|
          # this is really awful. how can i make this non-awful?
          k = "tag:#{k}" unless k.to_s == "architecture"
          h[k.to_s] = v
          h
        end
        get_filter_opts(tags)
      elsif tags.is_a? Array
        get_filter_opts( { "tag-key" => tags.map(&:to_s) })
      else
        get_filter_opts( { "tag-key" => [tags.to_s] })
      end
    end

    def get_filter_opts(filters)
      opts = {}
      filters.each_with_index do |(k, v), n|
        opts["Filter.#{n}.Name"] = k.to_s
        v = [ v ] unless v.is_a? Array
        v.each_with_index do |v, i|
          opts["Filter.#{n}.Value.#{i}"] = v.to_s
        end
      end
      opts
    end
  end
end

