module Stem
  module Util

    ## PVH - I know this function freaks you out - I see 2 options
    ## 1. use less magic

    ## def to_array(data)
    ##   return data if data.kind_of? Array
    ##   return [ ] if data.nil?
    ##   return [ data ]
    ## end

    ## 2. disallow config.json fields like "availability_zone" from taking non array arguments
    ## ->  "availability_zone": "us-east-1d"
    ## vs
    ## ->  "availability_zone": [ "us-east-1d", "us-east-1c" ]
    ## will break old config.jons files tho


    def to_array(data)
      [ data || [] ].flatten
    end

    def pick(data, &blk)
      array_of_data = to_array(data)
      item = array_of_data[rand(array_of_data.length)]
      blk.call(item) if blk and item
      item
    end

    def swirl
      @swirl ||= Swirl::EC2.new(
        :aws_access_key_id => ENV['AWS_ACCESS_KEY_ID'],
        :aws_secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
      )
    end
  end
end

