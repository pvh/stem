require 'optparse'

module Stem
  Version = 0.2

  module CLI
    extend self


    # Return a structure describing the options.
    def parse_options(args)
      opts = OptionParser.new do |opts|
        opts.banner = "Usage: stem COMMAND ..."

        opts.separator " "

        opts.separator "Examples:"
        opts.separator "  $ stem launch prototype.config prototype.sh"
        opts.separator "  $ stem list"
        opts.separator "  $ stem create name instance-id"

        opts.separator " "
        opts.separator "Options:"

        opts.on("-v", "--version", "Print the version") do |v|
          puts "Stem v#{Stem::Version}"
          exit
        end

        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit
        end
      end

      opts.separator ""

      opts.parse!(args)
    end

    def dispatch_command command, arguments
      case command
        when "launch"
          launch(*arguments)
        when "create"
          create(*arguments)
        when "list"
          list(*arguments)
        when "describe"
          describe(*arguments)
        when "destroy"
          destroy(*arguments)
        when nil
          puts "Please provide a command."
        else
          puts "Command \"#{command}\" not recognized."
      end
    end

    def launch config_file = nil, userdata_file = nil
      abort "No config file" unless config_file
      userdata = File.new(userdata_file).read() if userdata_file
      instance = Stem::Instance::launch(JSON.parse(File.new(config_file).read()), userdata)
      puts "New instance ID: #{instance}"
    end

    def create name = nil, instance = nil
      abort "Usage: create ami-name instance-to-capture" unless name && instance
      image_id = Stem::Image::create(name, instance)
      puts "New image ID: #{image_id}"
    end

    def describe what
      require 'pp'
      if (what[0..2] == "ami")
        pp Stem::Image::describe(what)
      elsif
        pp Stem::Instance::describe(what)
      end
    end

    def destroy instance = nil
      abort "Usage: destroy instance-id" unless instance
      Stem::Instance::destroy(instance)
    end

    def list *arguments
      Stem::Instance::list(*arguments)
    end
  end
end

