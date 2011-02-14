require 'spec_helper'

describe Stem::Image do

  context "tagged" do
    use_vcr_cassette

    it { should respond_to :tagged }

    it "should return nil if an empty hash is passed in" do
      Stem::Image.tagged([]).should be_nil
    end

    it "should return nil if an empty array is passed in" do
      Stem::Image.tagged([]).should be_nil
    end

    it "should return an empty array when no images exist with the specified tags" do
      Stem::Image.tagged(:faketag => 'does_not_exist').should == []
    end

    it "should retun an array of ami IDs when 2 images exist with the specified tags" do
      Stem::Image.tagged(:slot => 'logplex', :architecture => 'x86_64')
    end
  end
end

# tags
# :family => "postgresql",
# :release => "production",
# :created_at => "10/10/10 10:10",
