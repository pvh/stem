require 'spec_helper'

describe Stem::Util do
  include Stem::Util

  describe "tagset_to_hash" do
    it "returns a hash when fed a stupid tagset" do
      tagset = [
        {"value"=>"postgres9-server", "key"=>"type"},
        {"value"=>"production", "key"=>"version"}
      ]
      tagset_to_hash(tagset).should == {"type" => "postgres9-server", "version" => "production"}
    end

    it "returns a hash when there is only one tag" do
      tagset = [{"key" => "type", "value" => "postgres9-server"}]
      tagset_to_hash(tagset).should == {"type" => "postgres9-server"}
    end

    it "returns nil for tags with no value" do
      tagset = [{"key" => "deprecated"}]
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

  describe "aggregate_hash_options_for_ami!" do
    it "shouldn't alter the hash if 'ami' is in the config hash" do
      config = {'ami' => 'ami-STOUT1'}
      aggregate_hash_options_for_ami!(config).should == config
    end

    it "should raise an exception if no valid ami options are in the input" do
      lambda do
        aggregate_hash_options_for_ami!({})
      end.should raise_exception
    end

    describe "ami-name" do
      before do
        @config = { 'ami-name' => 'speedway_stout' }
        @ami_id = 'ami-STOUT1'
        Stem::Image.stub!(:named).and_return(@ami_id)
      end

      it "should look up the ami by name if 'ami-name' is in the input hash" do
        Stem::Image.should_receive(:named).and_return(@ami_id)
        aggregate_hash_options_for_ami!(@config)
      end

       it "should not include 'ami-name' in the result" do
        aggregate_hash_options_for_ami!(@config).keys.should_not include('ami-name')
      end

      it "should include the ami in the result" do
        aggregate_hash_options_for_ami!(@config)['ami'].should == @ami_id
      end

      it "should raise an exception if no ami matches the name" do
        Stem::Image.should_receive(:named).and_return(nil)
        lambda do
          aggregate_hash_options_for_ami!(@config)
        end.should raise_exception
      end
    end

    describe "ami-tags" do
      before do
        @config = { 'ami-tags' => { :brewery => 'alesmith' } }
        @ami_id = 'ami-SCOTCH'
        Stem::Image.stub!(:tagged).and_return([@ami_id])
      end

      it "should look up the ami by name if 'ami-tags' is in the input hash" do
        Stem::Image.should_receive(:tagged).and_return([@ami_id])
        aggregate_hash_options_for_ami!(@config)
      end

      it "should not include 'ami-tags' in the result" do
        aggregate_hash_options_for_ami!(@config).keys.should_not include('ami-name')
      end

      it "shuld include the ami in the result" do
        aggregate_hash_options_for_ami!(@config)['ami'].should == @ami_id
      end

      it "should raise an exception if no ami matches the tags" do
        Stem::Image.should_receive(:tagged).and_return([])
        lambda do
          aggregate_hash_options_for_ami!(@config)
        end.should raise_exception
      end
    end
  end
end
