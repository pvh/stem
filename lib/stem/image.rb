module Stem
  module Image
    include Util
    extend self

    def create name, instance, tags
      raise "You already have an image named '#{name}'" if named(name)
      image_id = swirl.call("CreateImage", "Name" => name, "InstanceId" => instance)["imageId"]
      unless tags.empty?
        # We'll retry this once if necessary due to consistency issues on the AWS side
        i = 0
        begin
          Tag::create(image_id, tags)
        rescue Swirl::InvalidRequest => e
          if i < 5 && e.message =~ /does not exist/
            i += 1
            retry
          end
          raise e
        end
      end
      image_id
    end

    def deregister image
      swirl.call("DeregisterImage", "ImageId" => image)["return"]
    end

    def named name
      i = swirl.call "DescribeImages", "Owner" => "self"
      ami = i["imagesSet"].select {|m| m["name"] == name }.map { |m| m["imageId"] }.first
    end

    def tagged tags
      return if tags.empty?
      opts = tags_to_filter(tags).merge("Owner" => "self")
      swirl.call("DescribeImages", opts)['imagesSet'].map {|image| image['imageId'] }
    end

    def describe image
      swirl.call("DescribeImages", "ImageId" => image)["imagesSet"][0]
    end
  end
end

