require 'tmpdir'
require 'fileutils'

module Stem
  module Userdata
    CREATE_ONLY = File::CREAT|File::EXCL|File::WRONLY

    extend self

    def compile(path, opts = {})
      raise "No absolute paths please" if path.index("/") == 0
      raise "must be a directory" unless File.directory?(path)
      Dir.mktmpdir do |tmp_path|
        # trailing dot copies directory contents to match actual cp -r semantics... go figure
        FileUtils.cp_r("#{path}/.", tmp_path)
        Dir.chdir tmp_path do
          process_erb(opts[:erb_binding])
          process_mustache(opts[:mustache_vars])
          raise "must contain a userdata.sh" unless File.exists?("userdata.sh")
          make_zip_shell
        end
      end
    end

    # todo: make this & process_mustache both use binding
    def process_erb(binding)
      Dir["**/*.erb.stem"].each do |file|
        raise "must pass :erb_binding when using .erb.stem files" unless binding
        require 'erb'
        puts "erb ... #{file}"
        File.open(file.gsub(/.erb.stem$/,""), CREATE_ONLY) do |fff|
          fff.write ERB.new(File.read(file), 0, '<>').result(binding)
        end
      end
    end 

    def process_mustache(vars)
      Dir["**/*.mustache.stem"].each do |file|
        raise "must pass :mustache_vars when using .mustache.stem files" unless vars
        require 'mustache'
        puts "mustache ... #{file}"
        File.open(file.gsub(/.mustache.stem$/,""), CREATE_ONLY) do |fff|
          fff.write Mustache.render(File.read(file), vars)
        end
      end
    end

    def make_zip_shell
      # We'll comment outside here, to keep from wasting valuable userdata bytes.
      # we decompress into /root/userdata, then run userdata.sh
      header = <<-'SHELL'
        #!/bin/bash
        exec >> /var/log/userdata.log 2>&1
        echo BOOTING `date`
        UD=~/userdata
        mkdir -p $UD
        tail -n +HEADER_LINES "$0" | tar -jx -C $UD -f -
        cd $UD
        exec bash userdata.sh
      SHELL
      process_header(header) + %x{tar --exclude *.stem -cv - . | bzip2 --best -}
    end

    def process_header(shell)
      shell.gsub(/HEADER_LINES/, (shell.split("\n").size + 1).to_s).gsub(/^ +/,'')
    end
  end
end

