require 'lib/stem/util'
include Stem::Util

describe "tagset_to_hash" do
  it "returns a hash when fed a stupid tagset" do
    tagset = {"item"=>[
      {"value"=>"postgres9-server", "key"=>"type"},
      {"value"=>"production", "key"=>"version"}]}
    tagset_to_hash(tagset).should == {"type" => "postgres9-server", "version" => "production"}
  end

  it "returns a hash when there is only one tag" do
    tagset = {"item" => {"key" => "type", "value" => "postgres9-server"}}
    tagset_to_hash(tagset).should == {"type" => "postgres9-server"}
  end

  it "returns nil for tags with no value" do
    tagset = {"item"=>[{"key" => "deprecated"}]}
    tagset_to_hash(tagset).should == {"deprecated" => nil}
  end
end

describe "filter_opts" do
  it "translates a hash into amazon FilterOpts" do
    tags = {"tag:version" => "production",
            "tag:family" => "postgres9-server"}

    get_filter_opts(tags).should == { "Filter.1.Value.0"=>"production",
                                      "Filter.0.Value.0"=>"postgres9-server",
                                      "Filter.1.Name"=>"tag:version",
                                      "Filter.0.Name"=>"tag:family" }
  end

  it "supports multiple values for the query" do
    tags = {"tag:version" => "production",
            "tag:family" => ["postgres84-server", "postgres9-server"]}

    get_filter_opts(tags).should == { "Filter.1.Value.0"=>"production",
                                      "Filter.0.Value.0"=>"postgres84-server",
                                      "Filter.0.Value.1"=>"postgres9-server",
                                      "Filter.1.Name"=>"tag:version",
                                      "Filter.0.Name"=>"tag:family" }
  end
end

describe "tags_to_filter" do
  it "translates tags into the aws style" do
    tags = {:version => "production",
             :family => "postgres9-server"}
    tags_to_filter(tags).should == get_filter_opts({"tag:version" => "production",
                                    "tag:family" => "postgres9-server"})
  end
  it "special-cases architecture tag" do
    tags = {:architecture => "i386"}
    tags_to_filter(tags).should == get_filter_opts({"architecture" => "i386"})
  end
end
