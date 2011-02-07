require 'rspec'
require 'lib/stem'

describe Stem::Userdata do
  describe '#compile' do
    it "should produce identical output with identical input" do
      output1 = Stem::Userdata.compile("spec/fixtures/userdata", :erb_binding => binding)
      sleep(1)  # Necessary to ensure different timestamps
      output2 = Stem::Userdata.compile("spec/fixtures/userdata", :erb_binding => binding)
      output1.should == output2
    end
  end
end