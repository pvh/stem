module Stem
  module Image
    extend self

    def capture name, instance
      description = {} # more to come here...
      swirl.call("CreateImage", "InstanceId" => instance, "Name" => name, "Description" => "%%" + description.to_json)["imageId"]
    end

    def image_named name
        i = swirl.call "DescribeImages", "Owner" => "self"
        ami = i["imagesSet"].select {|m| m["name"] == name }.map { |m| m["imageId"] }.first
    end

    def describe_image image
      swirl.call("DescribeImages", "ImageId" => image)["imagesSet"][0]
    end

    def deregister_image image
      swirl.call("DeregisterImage", "ImageId" => image)["return"]
    end
  end
end

