require 'vcr'
require 'timecop'
require 'lib/stem'

RSpec.configure do |c|
  c.extend VCR::RSpec::Macros
end

if ENV["VCR_RECORD"]
  puts "******** VCR RECORDING **********"

  VCR.config do |c|
    c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
    c.stub_with :webmock
    c.default_cassette_options = { :match_requests_on => [:uri, :method, :body], :record => :new_episodes }
    c.before_record do |i|
      if i.request.uri =~ /ec2\.amazonaws\.com/
        vars_to_strip = {
          "AWSAccessKeyId" => "AKIAABCDEFGHIJKLMNOP",
          "Signature" => "fakesignature",
          "Timestamp" => "2002-10-28T04%3A16%3A00Z"
        }
        vars_to_strip.each do |k,v|
          i.request.body.gsub!(/(#{k}=[^&$]+)(&|$)/, "#{k}=#{v}\\2")
        end
      end
    end
  end
else
  puts "******** VCR PLAYBACK **********"

  Timecop.freeze(Time.parse("2002-10-28T04:16:00Z"))

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

  # Stub out signature generation
  Swirl::EC2.class_eval do
    def compile_signature(method, body)
      "fakesignature"
    end
  end

  VCR::RequestMatcher.class_eval do
    # VALID_MATCH_ATTRIBUTES = [:method, :uri, :host, :path, :headers, :body, :body_params]

    def body
      request.body if match_requests_on?(:body)
    end

  end

end
