module Stem
  module Group
    include Util
    extend self

    ## Example Rules

    ## icmp://1.2.3.4/32
    ## icmp://GroupName
    ## icmp://UserId@GroupName
    ## icmp://UserId@
    ## tcp://0.0.0.0/0:22
    ## tcp://0.0.0.0/0:22-23
    ## tcp://10.0.0.0/8:    (this imples 0-65535
    ## udp://GroupName:4567
    ## udp://UserId@GroupName:4567-9999

    def create(name, rules = [])
      description = {}
      Stem.swirl.call("CreateSecurityGroup",  "GroupName" => name, "GroupDescription" => "%%" + JSON.dump(description))
      puts "Stem.swirl.call 'AuthorizeSecurityGroupIngress', #{{ "GroupName" => name }.merge(create_auth_rules(name, rules)).inspect}"
      Stem.swirl.call "AuthorizeSecurityGroupIngress", { "GroupName" => name }.merge(create_auth_rules(name, rules))
    end

    def create_auth_rules(name, rules)
      index = 0
      (default_rules(name) + rules).inject({}) { |hash,rule| index += 1; hash.merge(authorize(index, rule)) }
    end

    def default_rules(name)
      [ "tcp://#{name}:", "udp://#{name}:", "icmp://#{name}", "tcp://0.0.0.0/0:22" ]
    end

    def authorize_target(index, target)
      puts "authorize_target #{index} #{target}"
      if target =~ /^\d+\.\d+\.\d+.\d+\/\d+$/
        { "IpPermissions.#{index}.IpRanges.1.CidrIp"  => target }
      elsif target =~ /^(\w+)@(\w+)$/
        { "IpPermissions.#{index}.Groups.1.GroupName" => $2,
          "IpPermissions.#{index}.Groups.1.UserId"    => $1 }
      elsif target =~ /^(\w+)@$/
        { "IpPermissions.#{index}.Groups.1.UserId"    => $1 }
      else
        { "IpPermissions.#{index}.Groups.1.GroupName" => target }
      end
    end

    def authorize_ports(index, ports)
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

    def authorize(index, rule)
      if rule =~ /icmp:\/\/(.+)/
        { "IpPermissions.#{index}.IpProtocol"         => "icmp",
          "IpPermissions.#{index}.FromPort"           => "-1",
          "IpPermissions.#{index}.ToPort"             => "-1" }.merge(authorize_target(index,$1))
      elsif rule =~ /(tcp|udp):\/\/(.*):(.*)/
        { "IpPermissions.#{index}.IpProtocol"         => $1 }.merge(authorize_target(index,$2)).merge(authorize_ports(index,$3))
      else
        raise "bad rule: #{rule}"
      end
    end
  end
end

