require 'vcr'
require 'timecop'
require 'lib/stem'

RSpec.configure do |c|
  c.extend VCR::RSpec::Macros
end

if ENV["VCR_RECORD"]
  puts "******** VCR RECORDING **********"

  blinkytime = Time.now
  File.open("spec/fixtures/vcr_time", "w") { |f| f << Time.now.to_s }
  Timecop.freeze(blinkytime)

  VCR.config do |c|
    c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
    c.stub_with :webmock
    c.default_cassette_options = { :match_requests_on => [:uri, :method, :body], :record => :new_episodes }
  end
else
  puts "******** VCR PLAYBACK **********"

  blinkytime = Time.parse(File.read("spec/fixtures/vcr_time"))
  Timecop.freeze(blinkytime)

  VCR.config do |c|
    c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
    c.stub_with :webmock
    c.default_cassette_options = { :match_requests_on => [:uri, :method, :body], :record => :none }
  end

  # Stub out Stem config loading to use constant values
  Stem::Util.class_eval do
    private
    def load_config
      {
        :aws_access_key_id => "AKIAABCDEFGHIJKLMNOP",
        :aws_secret_access_key => "secret_access_key",
        :version => "2010-08-31"
      }
    end
  end
end
