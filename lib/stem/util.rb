module Stem
  module Util
    def swirl
      @swirl ||= Swirl::AWS.new :ec2, load_config
    end

    def tagset_to_hash(tagset)
      if tagset.is_a?(Hash)
        {tagset["item"]["key"] => tagset["item"]["value"]}
      else
        tagset.inject({}) do |h,item|
          k, v = item["key"], item["value"]
          h[k] = v
          h
        end
      end
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
      filters.keys.sort.each_with_index do |k, n|
        v = filters[k]
        opts["Filter.#{n}.Name"] = k.to_s
        v = [ v ] unless v.is_a? Array
        v.each_with_index do |v, i|
          opts["Filter.#{n}.Value.#{i}"] = v.to_s
        end
      end
      opts
    end

    private

    def load_config
      account = "default"
      etc = "#{ENV["HOME"]}/.swirl"
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
    end

    def aggregate_hash_options_for_ami!(config)
      if config["ami"]
        return config
      elsif config["ami-name"]
        name = config.delete("ami-name")
        config["ami"] = Image::named(name)
        throw "AMI named #{name} was not found. (Does it need creating?)" unless config["ami"]
      elsif config["ami-tags"]
        tags = config.delete('ami-tags')
        config["ami"] = Image::tagged(tags)[0]
        throw "AMI tagged with #{tags.inspect} was not found. (Does it need creating?)" unless config["ami"]
      else
        throw "No AMI specified."
      end
      config
    end

  end
end

