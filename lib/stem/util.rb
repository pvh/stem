module Stem
  module Util
    def array(value)
      [ value || [] ].flatten
    end

    def pick(data)
      array(data)[ rand(2**31) % array(data).size ]
    end

    def swirl
      @swirl ||= Swirl::EC2.new(
        :aws_access_key_id => ENV['AWS_ACCESS_KEY_ID'],
        :aws_secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
      )
    end
  end
end

