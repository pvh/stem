module Stem
  module Util
    def swirl
      account = "default"
      etc = "#{ENV["HOME"]}/.swirl"
      config = \
      if ENV["AWS_ACCESS_KEY_ID"] && ENV["AWS_SECRET_ACCESS_KEY"]
        {
          :aws_access_key_id => ENV["AWS_ACCESS_KEY_ID"],
          :aws_secret_access_key => ENV["AWS_SECRET_ACCESS_KEY"]
        }
      else
        account = account.to_sym
        data = YAML.load_file(etc)
        if data.key?(account)
          data[account]
        else
          abort("I don't see the account you're looking for")
        end
      end

      @swirl = Swirl::EC2.new config
    end

    def get_filter_opts(filters)
      opts = {}
      filters.each do |k, v|
        opts["Filter.1.Name"] = k
        v = [ v ] unless v.is_a? Array
        v.each_with_index do |v, i|
          opts["Filter.1.Value.#{i}"] = v.to_s
        end
      end
      opts
    end
  end
end

