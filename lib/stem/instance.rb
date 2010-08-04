module Stem
  module Instance
    extend self

    def launch config, userdata = nil
      throw "No config provided" unless config

      ami = nil
      if config["ami"]
        ami = config["ami"]
      elsif config["ami-name"]
        ami = image_named(config["ami-name"])
        throw "AMI named #{config["ami-name"]} was not found. (Does it need creating?)" unless ami
      end
      throw "No AMI specified." unless ami

      opt = {
        "MinCount" => "1",
        "MaxCount" => "1",
        "KeyName" => config["key_name"] || "default",
        "InstanceType" => config["instance_type"] || "m1.small",
        "ImageId" => ami
      }
      if config["availability_zone"]
        opt.merge! "Placement.AvailabilityZone" => config["availability_zone"]
      end

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

      puts "Success!"
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

    def describe instance
      swirl.call("DescribeInstances", "InstanceId" => instance)["reservationSet"][0]["instancesSet"][0]
    end

    def list

    end
  end
end
