module Stem
  module Family
    include Util
    extend self

    def ami_for(family, release, architecture = "x86_64")
      amis = Stem::Image::tagged(:family => family,
                                 :release => release, 
                                 :architecture => architecture)
      throw "More than one AMI matched release." if amis.length > 1
      amis[0]
    end

    def unrelease family, release_name
      prev = Stem::Image::tagged(:family => family, :release => release_name)
      prev.each { |ami| Stem::Tag::destroy(ami, :release => release_name) }
    end

    def member? family, ami
      desc = Stem::Image::describe(ami)
      throw "AMI #{ami} does not exist" if desc.nil?
      tagset_to_hash(desc["tagSet"])["family"] == family
    end

    def members family
      Stem::Image.tagged("family" => family)
    end

    def describe_members family
      Stem::Image.describe_tagged("family" => family)
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

      aggregate_hash_options_for_ami!(config)
      sha1 = image_hash(config, userdata)

      log.call "Beginning to build image for #{family}"
      log.call "Config:\n------\n#{ config.inspect }\n-------"
      instance_id = Stem::Instance.launch(config, userdata)

      log.call "Booting #{instance_id} to produce your prototype instance"
      wait_for_stopped instance_id, log

      timestamp = Time.now.utc.iso8601
      image_id = Stem::Image.create("#{family}-#{timestamp}",
                                    instance_id,
                                    {
                                      :created => timestamp,
                                      :family => family,
                                      :sha1 => sha1,
                                      :source_ami => config["ami"]
                                    })
      log.call "Image ID is #{image_id}"

      wait_for_available(image_id, log)

      log "Terminating #{instance_id} now that the image is captured"
      Stem::Instance::destroy(instance_id)
    end

    def image_already_built?(family, config, userdata)
      aggregate_hash_options_for_ami!(config)
      sha1 = image_hash(config, userdata)
      !Stem::Image.tagged(:family => family, :sha1 => sha1).empty?
    end

    def image_hash(config, userdata)
      Digest::SHA1::hexdigest([config.to_s, userdata].join(' '))
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
      log.call "Waiting for image to finish capturing..."
      while sleep 10
        begin
          state = Stem::Image.describe(image_id)["imageState"]
          log.call "Image #{image_id} #{state}"
          case state
          when "available"
            log.call("Image capturing succeeded")
            break
          when "pending" #continue
          when "terminated"
            log "Image capture failed (#{image_id})"
            return false
          else throw "Image unexpectedly entered #{state}";
          end
        rescue Swirl::InvalidRequest => e
          raise unless e.message =~ /does not exist/
        end
      end
    end
  end
end
