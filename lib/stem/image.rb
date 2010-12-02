module Stem
  module Image
    include Util
    extend self

    def create name, instance, *tags
      raise "You already have an image named '#{name}'" if named(name)
      image_id = swirl.call("CreateImage", "Name" => name, "InstanceId" => instance)["imageId"]
      Tag::create(image_id, tags) unless tags.empty?
      image_id
    end

    def deregister image
      swirl.call("DeregisterImage", "ImageId" => image)["return"]
    end

    def named name
      i = swirl.call "DescribeImages", "Owner" => "self"
      ami = i["imagesSet"].select {|m| m["name"] == name }.map { |m| m["imageId"] }.first
    end

    def tagged *tags
      return if tags.empty?
      opts = { "tag-key" => tags.map {|t| t.to_s } }
      opts = get_filter_opts(opts).merge("Owner" => "self")
      swirl.call("DescribeImages", opts)['imagesSet'].map {|image| image['imageId'] }
    end

    def describe image
      swirl.call("DescribeImages", "ImageId" => image)["imagesSet"][0]
    end
  end
end

