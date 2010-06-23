require 'json'
require 'swirl'
require 'pp'

c = Swirl::EC2.new

CONFIG = ARGV[0]
USERDATA = ARGV[1]

config = JSON.parse File.read ARGV[0]
throw "No config"

ebs = config["volumes"].select {|v| v["media"] == "ebs"}

# XXX: check that the ebs group is ok before starting to create volumes

snapshots = []
devices = []
ebs.each do |v|
  volumeId = c.call("CreateVolume", "Size" => v["size"].to_s,  "AvailabilityZone" => "us-east-1b")["volumeId"]
  snapshotId = c.call("CreateSnapshot", "VolumeId" => volumeId)["snapshotId"]
  snapshots << snapshotId
  devices << v["device"]
end

opt = {
  "MinCount" => "1",
  "MaxCount" => "1",
  "KeyName" => "default",
  "ImageId" => config["ami32"],
  "BlockDeviceMapping.#.Ebs.SnapshotId" => snapshots,
  "BlockDeviceMapping.#.DeviceName" => devices
}
opt.merge({ "UserData" => Base64.encode64( File.read(USERDATA) )}) if File.read(USERDATA)

pp c.call "RunInstances", opt

