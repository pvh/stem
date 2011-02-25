require 'spec_helper'

describe Stem::Family do

  describe "ami_for" do
    it { should respond_to :ami_for }

    it "should return an AMI id when given the right input" do
      Stem::Image.should_receive(:tagged).with(
         :family => "postgres",
         :release => "production",
         :architecture => "x86_64"
         ).and_return(["ami-XXXXXX"])
      Stem::Family.ami_for("postgres", "production").should == "ami-XXXXXX"
    end

    it "should allow you to specify i386 architecture" do
      Stem::Image.should_receive(:tagged).with(
        :family => "postgres",
        :release => "production",
        :architecture => "i386"
        ).and_return(["ami-XXXXXX"])
      Stem::Family.ami_for("postgres", "production", "i386").should == "ami-XXXXXX"
    end

    it "should throw an error if there is more than one AMI matching a release" do
      Stem::Image.should_receive(:tagged).and_return(["ami-XXXXXX", "ami-BADBEEF"])
      lambda { Stem::Family.ami_for("postgres", "production", "i386") }.should raise_error
    end
  end

  describe "unrelease" do
    it { should respond_to :unrelease}

    it "can unrelease nothing" do
      Stem::Image::should_receive(:tagged).and_return([])
      Stem::Family::unrelease("postgres", "dummy")
    end

    it "should look up released images using tags" do
      Stem::Image.should_receive(:tagged).with({
        :family => 'postgres',
        :release => 'production'
      }).and_return([])
      Stem::Family.unrelease("postgres", "production")
    end

    it "can unrelease the previous release" do
      amis = ["ami-F00D", "ami-BEEF"]
      Stem::Image::should_receive(:tagged).and_return(amis)
      Stem::Tag::should_receive(:destroy).ordered.with(amis[0], :release => "production")
      Stem::Tag::should_receive(:destroy).ordered.with(amis[1], :release => "production")
      Stem::Family::unrelease("postgres", "production")
    end
  end

  describe "member?" do
    use_vcr_cassette

    it { should respond_to :member? }

    it "throws an exception for missing AMIs" do
      Stem::Image::should_receive(:describe).and_return(nil)
      lambda { Stem::Family::member?("postgres", "ami-BADAMI") }.should raise_error
    end

    it "returns true for AMIs in a family" do
      Stem::Family.member?("logplex", "ami-0286766b").should be_true
    end

    it "returns false for AMIs not in a family" do
      Stem::Family.member?("logplex", "ami-0686766f").should be_false
    end
  end

  describe "members" do
    use_vcr_cassette

    it { should respond_to :members }

    it "should call Stem::Image.tagged with the family tag" do
      f = "postgres"
      Stem::Image.should_receive(:tagged).with("family" => f).and_return([])
      Stem::Family.members(f)
    end

    it "should return an empty array when no members exist" do
      Stem::Image.should_receive(:tagged).and_return([])
      Stem::Family.members("postgres-protoss").should == []
    end

    it "should return the AMI IDs when members exist" do
      amis = [ "ami-00000001", "ami-00000002" ]
      Stem::Image.should_receive(:tagged).and_return(amis)
      Stem::Family.members("postgres").should == amis
    end
  end

  describe "describe_members" do
    use_vcr_cassette

    it { should respond_to :describe_members }

    it "should call Stem::Image.describe_tagged with the family tag" do
      f = "postgres"
      Stem::Image.should_receive(:describe_tagged).with("family" => f)
      Stem::Family.describe_members(f)
    end
  end

  describe "release" do
    it { should respond_to :release }

    context "image exists" do
      before do
        Stem::Family.stub(:member?).and_return(true)
        Stem::Family.stub(:unrelease).and_return(true)
      end

      it "should unrelease the existing release prior to tagging a new one" do
        Stem::Family.should_receive(:unrelease).ordered
        Stem::Tag.should_receive(:create).ordered
        Stem::Family::release("postgres", "production", "ami-XXXXXX")
      end

      it "should tag a new release for 1 AMI" do
        Stem::Tag.should_receive(:create).with(
          "ami-XXXXXX",
          :release => 'production'
        ).and_return('true')
        Stem::Family::release("postgres", "production", "ami-XXXXXX")
      end

      it "should tag a new release for 2 AMIs" do
        amis = ["ami-XXXXX1", "ami-XXXXX2"]
        Stem::Tag.should_receive(:create).with(
          amis[0],
          :release => 'production'
        ).ordered.and_return('true')
        Stem::Tag.should_receive(:create).with(
          amis[1],
          :release => 'production'
        ).ordered.and_return('true')
        Stem::Family::release("postgres", "production", *amis)
      end

      it "should become the release for a version"
    end

  end

  describe "build_image" do
    it { should respond_to :build_image }
  end

  describe "image_hash" do
    it { should respond_to :image_hash }

    it "should return the SHA1 hash of the config.to_s and userdata joined by a space" do
      sha1 = Digest::SHA1.hexdigest("config userdata")
      Stem::Family.image_hash("config", "userdata").should == sha1
    end
  end

  describe "image_already_built?" do
    before do
      @family = "great_beers"
      @config =   {
        "arch" => "32",
        "ami" => "ami-714ba518",
        "instance_type" => "c1.medium"
      }
      @userdata = "echo 'some useful script'"
      @sha1 ||= Stem::Family.image_hash(@config, @userdata)
      @ami_id = "ami-STOUT2"
      Stem::Image.stub!(:tagged).and_return([@ami_id])
    end

    it { should respond_to :image_already_built? }

    it "should look for images tagged with the family and sha1" do
      Stem::Image.should_receive(:tagged).with({
        :family => @family,
        :sha1 => @sha1
      }).and_return([])
      Stem::Family.image_already_built?(@family, @config, @userdata)
    end

    it "should return true if an image with the given family and sha1 exists" do
      Stem::Image.stub!(:tagged).and_return([@ami_id])
      Stem::Family.image_already_built?(@family, @config, @userdata).should == true
    end

    it "should return false if there's no image with the given family and sha1" do
      Stem::Image.stub!(:tagged).and_return([])
      Stem::Family.image_already_built?(@family, @config, @userdata).should == false
    end
  end
end

# tags
# :family => "postgresql",
# :release => "production",
# :created_at => "10/10/10 10:10",
