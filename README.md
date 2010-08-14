Stem
-------
EC2 made easy.

Introduction
-------
Stem is a thin, light-weight EC2 instance management library which abstracts the Amazon EC2 API and provides an intuitive interface for designing, launching, and managing running instances.

Stem is named after the model it encourages -- simple AMIs created on demand with many running copies derived from that.

Usage
------
You can use Stem to manage your instances either from the commandline or directly via the library. You should create an instance which will serve as your "stem" and be converted into an AMI. Once you have tested this instance, create a snapshot of the instance, then use it by name to launch new instances with their own individual configuration.

Here's a simple example from the command line. Begin by launching the example prototype instance.

$ bin/stem launch chrysanthemum/prototype/config.json chrysanthemum/prototype/userdata.sh

The config.json file specifies which AMI to start from, and what kind of EBS drive configuration to use. It is important that the drives are specified in the configuration file as any drives attached to the instance after launch will not become part of the eventual AMI you are creating 

You can monitor the instance's fabrication process via

$ stem list

The instance you created will boot, install some packages on top of a stock Ubuntu 10.4 AMI, then (if everything goes according to plan) shut itself down and go into a "stopped" state that indicates success. If any part of the stem fabrication fails, the instance will remain running. Once the instance reaches stopped, type

$ stem create postgres-server <instance-id>

The AMI may take as long as half an hour to build, depending on how the gremlins in EC2 are behaving on any given day. You can check on their progress with

$ bin/amy

If the AMI fabrication reaches the state "failed" you will have to manually reissue the `create` command and hope that the gremlins are more forgiving the second time around.

Now that you have a simple postgres-server, you'll want to boot it up and create a database on it with some unique credentials! One of the simplest ways to solve this problem is to provide the instance with a templated userdata script which will perform per-instance configuration. I like mustache for this purpose.

$ mustache test-data.yaml server/userdata.sh.mustache > server/userdata.sh
$ stem launch server/config.json server/userdata.sh

You can, of course, delete the produced userdata.sh once the instance is launched.

Inspiration and Thanks
-----------
Stem is almost entirely based on Orion Henry's Judo gem, and Blake Mizerany's work on variously patton, carealot, napkin, and several other experiments. Thanks also for feedback, testing and patches from Adam Wiggins, Mark McGranahan, Noah Zoschke, and Jason Dusek.

