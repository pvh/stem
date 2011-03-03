$:.unshift File.dirname(__FILE__)

require 'swirl/aws'
require 'json'

require 'stem/cli'
require 'stem/util'
require 'stem/group'
require 'stem/userdata'
require 'stem/instance'
require 'stem/instance_types'
require 'stem/image'
require 'stem/ip'
require 'stem/key_pair'
require 'stem/tag'

module Stem
  autoload :Family, 'stem/family'
end
