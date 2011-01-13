module Stem
  module KeyPair
    include Util
    extend self

    def create(name)
        swirl.call('CreateKeyPair', 'KeyName' => name)
        true
      rescue Swirl::InvalidRequest => e
        raise e unless e.message =~ /The keypair '\S+' already exists/
        false
    end

    def destroy(name)
        destroy!(name)
        true
      rescue Swirl::InvalidRequest => e
        puts "===> #{e.class}"
        puts "===> #{e.message}"
        puts "#{e.backtrace.join("\n")}"
        false
    end

    def destroy!(name)
      swirl.call('DeleteKeyPair', 'KeyName' => name)
    end

    def describe(names)
      swirl.call('DescribeKeyPairs', 'KeyName' => names)
    end

    def exists?(name)
        true if describe(name)
      rescue Swirl::InvalidRequest => e
        raise e unless e.message.match(/does not exist$/)
        false
    end

    def import(name, key_string)
        require 'base64'
        swirl.call('ImportKeyPair', {
          'KeyName' => name,
          'PublicKeyMaterial' => Base64.encode64(key_string)
        })
        true
      rescue Swirl::InvalidRequest => e
        raise e unless e.message =~ /The keypair '\S+' already exists/
        false
    end

  end
end