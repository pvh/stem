module Stem
  module Util
    def swirl
      @swirl ||= Swirl::EC2.new(
        :aws_access_key_id => ENV['AWS_ACCESS_KEY_ID'],
        :aws_secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
      )
    end
  end
end

