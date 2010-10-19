#!/bin/bash

# Note that `-o' means enable while `+o' means disable.
set -o errexit
set -o nounset
set -o pipefail
set -o functrace
set -o errtrace
set +o histexpand


declare -ar packages=( lxc nmap git-core
                       irb ruby rubygems1.8
                       libopenssl-ruby libjson-ruby )
aptitude install --assume-yes "${packages[@]}"

/usr/bin/updatedb

locale-gen en_DK.UTF-8

cat packet/etc/fstab > /etc/fstab
cat packet/etc/environment > /etc/environment
cat packet/etc/profile.d/ruby.sh > /etc/profile.d/ruby.sh

