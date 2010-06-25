require 'swirl'
require 'json'

module GreenField
  extend self

  def swirl
    @swirl ||= Swirl::EC2.new
  end

  def create config, userdata = nil
    avail_zone = config["availability_zone"] || "us-east-1c"

    ami = nil
    if config["ami32"]
      ami = config["ami32"]
    elsif config["ami-name"]
      i = swirl.call "DescribeImages", "Owner" => "self"
      ami = i["imagesSet"].select {|m| m["name"] == config["ami-name"] }.map { |m| m["imageId"] }.first
    end
    throw "No AMI specified." unless ami

    opt = {
      "Placement.AvailabilityZone" => avail_zone,
      "MinCount" => "1",
      "MaxCount" => "1",
      "KeyName" => "default",
      "ImageId" => ami
    }

    if config["volumes"]
      ebs = config["volumes"].select {|v| v["media"] == "ebs"}
      # XXX: check that the ebs group is ok before starting to create volumes

      devices = []
      sizes = []
      ebs.each do |v|
        puts "Adding a volume of #{v["size"]} to be mounted at #{v["device"]}."
        devices << v["device"]
        sizes << v["size"].to_s
      end

      opt.merge! "BlockDeviceMapping.#.Ebs.VolumeSize" => sizes,
                 "BlockDeviceMapping.#.DeviceName" => devices
    end

    if userdata
      puts "Userdata provided."
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
    swirl.call "CreateImage", "InstanceId" => instance, "Name" => name, "Description" => "%%" + description.to_json
  end

  def allocate_ip
    swirl.call("AllocateAddress")["publicIp"]
  end

  def associate_ip ip, instance
    result = swirl.call("AssociateAddress", "InstanceId" => instance, "PublicIp" => ip)["return"]
    result == true
  end

  def inspect instance
    swirl.call("DescribeInstances", "InstanceId" => instance)["reservationSet"][0]["instancesSet"][0]
  end
end
