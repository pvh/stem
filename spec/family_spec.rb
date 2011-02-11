require 'rspec'
require 'lib/stem'

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
    
    it "can unrelease the previous release" do
      Stem::Image::should_receive(:tagged).and_return(["ami-F00D", "ami-BEEF"])
      Stem::Tag::should_receive(:destroy).twice.with(/ami-.+/, {:release => "production"})
      Stem::Family::unrelease("postgres", "production")
    end
  end

  describe "in_family" do
    it { should respond_to :in_family? }
    it "throws an exception for missing AMIs" do
      Stem::Image::should_receive(:describe).and_return(nil)
      lambda { Stem::Family::in_family?("postgres", "ami-BADAMI") }.should raise_error
    end
    
    it "returns true for AMIs in a family"
    it "returns false for AMIs not in a family"
  end

  describe "release" do
    it { should respond_to :release }
    
    it "should tag a new release" do
    end
    
    it "should become the release for a version"
  end
end

# tags
# :family => "postgresql",
# :release => "production",
# :created_at => "10/10/10 10:10",
