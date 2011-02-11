require 'sha1'

module Stem
  module Family
    extend self

    def ami_for(family, release, architecture = "x86_64")
      amis = Stem::Image::tagged(:family => family,
                                 :release => release, 
                                 :architecture => architecture)
      throw "More than one AMI matched release." if amis.length > 1
      amis[0]
    end

    def unrelease family, release
      prev = Stem::Image::tagged(:family => family, :release => release)
      prev.each { |ami| Stem::Tag::destroy(ami, :release => release) }
    end
    
    def member? family, ami
      desc = Stem::Image::describe(ami)
      throw "AMI #{ami} does not exist" if desc.nil?
      tagset_to_hash(["tagSet"])["family"] == family
    end
    
    def release family, release_name, *amis
      amis.each do |ami|
        throw "#{ami} not part of #{family}" unless member?(family, ami)
      end
      unrelease family, release_name
      amis.each { |ami| Stem::Tag::create(ami, :release => release_name) }
    end

    def build_image(family, config, userdata)
      log = lambda { |msg|
        puts "[#{family}|#{Time.now.to_s}] #{msg}"
      }

      log.call "Beginning to build image for #{family}"
      log.call "Config:\n------\n#{ config.inspect }\n-------"
      instance_id = Stem::Instance.launch(config, userdata)

      log.call "Booting #{instance_id} to produce your prototype instance"
      wait_for_stopped instance_id, log

      build_hash = SHA1::hexdigest( userdata + config.to_s )
      image_id = Stem::Image.create("#{family}-#{build_hash}",
                                    instance_id,
                                    {
                                      :family => family,
                                      :created => Time.now.utc.iso8601
                                    })
      log.call "Image ID is #{image_id}"

      wait_for_available(image_id, log)

      log "Terminating #{instance_id} now that the image is captured"
      Stem::Instance::terminate(instance_id)
    end

    protected

    def wait_for_stopped(instance_id, log)
      log.call "waiting for instance to reach state stopped -- "
      while sleep 10
        state = Stem::Instance.describe(instance_id)["instanceState"]["name"]
        log.call "instance #{instance_id} #{state}"
        break if state == "stopped"
      end
    end

    def wait_for_available(image_id, log)
      log.call "waiting for image to finish capturing..."
      while sleep 10
        begin
          state = Stem::Image.describe(image_id)["imageState"]
          log.call "image #{image_id} #{state}"
          if state == "available"
            log.call "image capturing succeeded"
            break
          elsif state == "pending"
            # continue
          else
            throw "image unexpectedly entered #{state}"
          end
        rescue Swirl::InvalidRequest => e
          raise unless e.message =~ /does not exist/
        end
      end
    end
  end
end
