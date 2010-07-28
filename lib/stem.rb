$:.unshift File.dirname(__FILE__)

require 'swirl'
require 'json'
require 'stem/cli'

module Stem
  extend self

  def swirl
    @swirl ||= Swirl::EC2.new(
      :aws_access_key_id => ENV['AWS_ACCESS_KEY_ID'],
      :aws_secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
    )
  end

  def launch config, userdata = nil
    avail_zone = config["availability_zone"]

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

  def allocate_ip
    swirl.call("AllocateAddress")["publicIp"]
  end

  def associate_ip instance, ip
    result = swirl.call("AssociateAddress", "InstanceId" => instance, "PublicIp" => ip)["return"]
    result == "true"
  end

  # TODO: check this
  def release_ip ip
    result = swirl.call("ReleaseAddress", "PublicIp" => ip)
  end

  def describe instance
    swirl.call("DescribeInstances", "InstanceId" => instance)["reservationSet"][0]["instancesSet"][0]
  end

  # this is a piece of crap
  def list
    instances = swirl.call("DescribeInstances")

    lookup = {}
    instances["reservationSet"].each {|r| r["instancesSet"].each { |i| lookup[i["imageId"]] = nil } }
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

    instances["reservationSet"].each do |r|
      r["instancesSet"].each do |i|
        name = lookup[i["imageId"]]
        puts "%-15s %-15s %-15s %s" % [ i["instanceId"], i["ipAddress"] || "no ip", i["instanceState"]["name"], name ? name : i["imageId"]]
      end
    end
  end

  def restart instance_id
    swirl.call "RebootInstances", "InstanceId" => instance_id
  end

  def destroy instance_id
    swirl.call "TerminateInstances", "InstanceId" => instance_id
  end

end
