$:.unshift File.dirname(__FILE__)

require 'swirl'
require 'json'

require 'stem/cli'
require 'stem/instance'
require 'stem/image'
require 'stem/ip'

module Stem
  extend self

  def swirl
    @swirl ||= Swirl::EC2.new(
      :aws_access_key_id => ENV['AWS_ACCESS_KEY_ID'],
      :aws_secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
    )
  end
end
