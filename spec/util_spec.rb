require 'lib/stem/util'
include Stem::Util

describe "tag support utilities" do
  it "returns a hash when fed a stupid tagset" do
    tagset = {"item"=>[{"value"=>"postgres9-server", "key"=>"type"}, {"value"=>"production", "key"=>"version"}]}
    tagset_to_hash(tagset).should == {"type" => "postgres9-server", "version" => "production"}
  end

  it "returns nil for tags with no value" do
    tagset = {"item"=>[{"key" => "deprecated"}]}
    tagset_to_hash(tagset).should == {"deprecated" => nil}
  end

  it "returns an array for multiple tags" do
    tagset = {"item"=>[ {"value"=>"staging", "key" => "version"}, {"value"=>"production", "key"=>"version"}]}
    # yeah, this test result is a little fragile, since the order of the results is arbitrary
    tagset_to_hash(tagset).should == { "version" => ["staging", "production"] }
  end

  it "supports three or more multiple tags for a key" do
    tagset = {"item"=>[ {"value"=>"staging", "key" => "version"}, {"value"=>"production", "key"=>"version"}, {"value" => "testing", "key" => "version"}]}
    # yeah, this test result is a little fragile, since the order of the results is arbitrary
    tagset_to_hash(tagset).should == { "version" => ["staging", "production", "testing"] }
  end
end
