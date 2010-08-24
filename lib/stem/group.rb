module Stem
  module Group
    include Util
    extend self

    ## Example Rules

    ## icmp://1.2.3.4/32
    ## icmp://GroupName
    ## icmp://GroupName@UserId
    ## icmp://@UserId
    ## tcp://0.0.0.0/0:22
    ## tcp://0.0.0.0/0:22-23
    ## tcp://10.0.0.0/8:    (this imples 0-65535
    ## udp://GroupName:4567
    ## udp://GroupName@UserID:4567-9999

    def get(name)
        swirl.call("DescribeSecurityGroups", "GroupName.1" => name)["securityGroupInfo"].first
      rescue Swirl::InvalidRequest
        raise e unless e.message =~ /The security group '\S+' does not exist/
        nil
    end

    def create(name, rules = nil)
        create!(name, rules)
        true
      rescue Swirl::InvalidRequest => e
        raise e unless e.message =~ /The security group '\S+' already exists/
        false
    end

    def create!(name, rules = nil)
      description = {}
      swirl.call "CreateSecurityGroup",  "GroupName" => name, "GroupDescription" => "%%" + description.to_json
      auth(name, rules) if rules
    end

    def destroy(name)
        destroy!(name)
        true
      rescue Swirl::InvalidRequest => e
        puts "===> #{e.class}"
        puts "===> #{e.message}"
        puts "#{e.backtrace.join("\n")}"
        false
    end

    def destroy!(name)
      swirl.call "DeleteSecurityGroup", "GroupName" => name
    end

    def auth(name, rules)
      index = 0
      args = rules.inject({"GroupName" => name}) do |i,rule|
          index += 1;
          rule_hash = gen_authorize(index, rule)
          i.merge(rule_hash)
      end
      swirl.call "AuthorizeSecurityGroupIngress", args
    end

    def gen_authorize_target(index, target)
      if target =~ /^\d+\.\d+\.\d+.\d+\/\d+$/
        { "IpPermissions.#{index}.IpRanges.1.CidrIp"  => target }
      elsif target =~ /^(\w+)@(\w+)$/
        { "IpPermissions.#{index}.Groups.1.GroupName" => $1,
          "IpPermissions.#{index}.Groups.1.UserId"    => $2 }
      elsif target =~ /^@(\w+)$/
        { "IpPermissions.#{index}.Groups.1.UserId"    => $1 }
      else
        { "IpPermissions.#{index}.Groups.1.GroupName" => target }
      end
    end

    def gen_authorize_ports(index, ports)
      if ports =~ /^(\d+)-(\d+)$/
        { "IpPermissions.#{index}.FromPort"           => $1,
          "IpPermissions.#{index}.ToPort"             => $2 }
      elsif ports =~ /^(\d+)$/
        { "IpPermissions.#{index}.FromPort"           => $1,
          "IpPermissions.#{index}.ToPort"             => $1 }
      elsif ports == ""
        { "IpPermissions.#{index}.FromPort"           => "0",
          "IpPermissions.#{index}.ToPort"             => "65535" }
      else
        raise "bad ports: #{rule}"
      end
    end

    def gen_authorize(index, rule)
      if rule =~ /icmp:\/\/(.+)/
        { "IpPermissions.#{index}.IpProtocol"         => "icmp",
          "IpPermissions.#{index}.FromPort"           => "-1",
          "IpPermissions.#{index}.ToPort"             => "-1" }.merge(gen_authorize_target(index,$1))
      elsif rule =~ /(tcp|udp):\/\/(.*):(.*)/
        { "IpPermissions.#{index}.IpProtocol"         => $1 }.merge(gen_authorize_target(index,$2)).merge(gen_authorize_ports(index,$3))
      else
        raise "bad rule: #{rule}"
      end
    end
  end
end

