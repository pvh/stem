module Stem
  module Ip
    include Util

    extend self
    def allocate
      swirl.call("AllocateAddress")["publicIp"]
    end

    def associate ip, instance
      result = swirl.call("AssociateAddress", "InstanceId" => instance, "PublicIp" => ip)["return"]
      result == "true"
    end

    def disassociate ip
      result = swirl.call("DisassociateAddress", "PublicIp" => ip)
    end

    def release ip
      result = swirl.call("ReleaseAddress", "PublicIp" => ip)
    end
  end
end
