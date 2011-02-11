module Stem
  module Family
    extend self

    def ami_for(family, release, architecture = "x86_64")
      amis = Stem::Image::tagged(:family => family,
                                 :release => release, 
                                 :architecture => architecture)
      throw "More than one AMI matched release." if amis.length > 1
      amis[0]
    end

    def unrelease family, release
      prev = Stem::Image::tagged(:family => family, :release => release)
      prev.each { |ami| Stem::Tag::destroy(ami, :release => release) }
    end
    
    def member? family, ami
      desc = Stem::Image::describe(ami)
      throw "AMI #{ami} does not exist" if desc.nil?
      tagset_to_hash(["tagSet"])["family"] == family
    end
    
    def release family, release_name, *amis
      amis.each do |ami|
        throw "#{ami} not part of #{family}" unless member?(family, ami)
      end
      unrelease family, release_name
      amis.each { |ami| Stem::Tag::create(ami, :release => release_name) }
    end
  end
end
