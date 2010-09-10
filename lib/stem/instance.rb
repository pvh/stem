module Stem
  module Instance
    include Util
    extend self

    def launch config, userdata = nil
      throw "No config provided" unless config

      ami = nil
      if config["ami"]
        ami = config["ami"]
      elsif config["ami-name"]
        ami = Image::named(config["ami-name"])
        throw "AMI named #{config["ami-name"]} was not found. (Does it need creating?)" unless ami
      end
      throw "No AMI specified." unless ami

      opt = {
        "SecurityGroup.#" => config["groups"] || [],
        "MinCount"        => "1",
        "MaxCount"        => "1",
        "KeyName"         => config["key_name"] || "default",
        "InstanceType"    => config["instance_type"] || "m1.small",
        "ImageId"         => ami
      }

      opt.merge! "Placement.AvailabilityZone" => config["availability_zone"] if config["availability_zone"]

      if config["volumes"]
        devices = []
        sizes = []
        config["volumes"].each do |v|
          puts "Adding a volume of #{v["size"]} to be mounted at #{v["device"]}."
          devices << v["device"]
          sizes << v["size"].to_s
        end

        opt.merge! "BlockDeviceMapping.#.Ebs.VolumeSize" => sizes,
                   "BlockDeviceMapping.#.DeviceName" => devices
      end

      if userdata
        puts "Userdata provided, encoded and sent to the instance."
        opt.merge!({ "UserData" => Base64.encode64(userdata)})
      end

      response = swirl.call "RunInstances", opt

      response["instancesSet"].each do |i|
        return i["instanceId"]
      end
    end

    def restart instance_id
      swirl.call "RebootInstances", "InstanceId" => instance_id
    end

    def destroy instance_id
      swirl.call "TerminateInstances", "InstanceId" => instance_id
    end

    def stop instance_id
      swirl.call "StopInstances", "InstanceId" => instance_id
    end

    def start instance_id
      swirl.call "StartInstances", "InstanceId" => instance_id
    end

    def describe instance
      throw "You must provide an instance ID to describe" unless instance
      swirl.call("DescribeInstances", "InstanceId" => instance)["reservationSet"][0]["instancesSet"][0]
    end

    def list
      instances = swirl.call("DescribeInstances")

      lookup = {}
      instances["reservationSet"].each do |r|
        r["instancesSet"].each do |i|
          lookup[i["imageId"]] = nil
        end
      end
      amis = swirl.call("DescribeImages", "ImageId" => lookup.keys)["imagesSet"]

      amis.each do |ami|
        name = ami["name"] || ami["imageId"]
        if !ami["description"] || ami["description"][0..1] != "%%"
          # only truncate ugly names from other people (never truncate ours)
          name.gsub!(/^(.{8}).+(.{8})/) { $1 + "..." + $2 }
          name = "(foreign) " + name
        end
        lookup[ami["imageId"]] = name
      end

      reservations = instances["reservationSet"]
      unless reservations.nil? or reservations.empty?
        puts "------------------------------------------"
        puts "Instances"
        puts "------------------------------------------"
        reservations.each do |r|
          groups = r["groupSet"].map { |g| g["groupId"] }.join(",")
          r["instancesSet"].each do |i|
              name = lookup[i["imageId"]]
              puts "%-15s %-15s %-15s %-20s %s" % [ i["instanceId"], i["ipAddress"] || "no ip", i["instanceState"]["name"], groups, name ]
          end
        end
      end

      result = swirl.call "DescribeImages", "Owner" => "self"
      images = result["imagesSet"].select { |img| img["name"] }
      unless images.nil? or images.empty?
        puts "------------------------------------------"
        puts "AMIs"
        puts "------------------------------------------"
        iwidth = images.map { |img| img["name"].length }.max + 1
        images.each do |img|
          puts "%-#{iwidth}s %s" % [ img["name"], img["imageId"] ]
        end
      end
    end
  end
end
