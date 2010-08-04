module Stem
  module Image
    extend self

    def snapshot name, instance
      description = {}
      swirl.call("CreateImage", "InstanceId" => instance, "Name" => name, "Description" => "%%" + description.to_json)["imageId"]
    end

    def release image
      swirl.call("DeregisterImage", "ImageId" => image)["return"]
    end

    def named name
        i = swirl.call "DescribeImages", "Owner" => "self"
        ami = i["imagesSet"].select {|m| m["name"] == name }.map { |m| m["imageId"] }.first
    end

    def describe image
      swirl.call("DescribeImages", "ImageId" => image)["imagesSet"][0]
    end
  end
end

