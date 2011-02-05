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
          # Set constant timestamps for all files to guarantee hashing consistency
          set_all_timestamps(tmp_path, "200210272016")
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
      header = <<-SHELL
#!/bin/bash
exec >> /var/log/userdata.log 2>&1
date --utc '+BOOTING %FT%TZ'
UD=~/userdata
mkdir -p $UD
sed '1,/^#### THE END$/ d' "$0" | tar -jx -C $UD
cd $UD
exec bash userdata.sh
#### THE END
      SHELL
      header + %x{tar --exclude \\*.stem -cv . | bzip2 --best -}
    end

    def set_all_timestamps(file_or_dir, time)
      Dir.foreach(file_or_dir) do |item|
        path = file_or_dir + '/' + item
        if File.directory?(path) && item != '.'
          next if item == '..'
          set_all_timestamps(path, time)
        else
          `touch -t #{time} #{path}`
        end
      end
    end

  end
end

