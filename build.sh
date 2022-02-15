#!/usr/bin/env bash

agent_url=${1:-https://checkmk.bennerweb.net/cmk/check_mk/agents/check-mk-agent_2.0.0p20-1_all.deb}
xinetd_url=${2:-https://slackonly.com/pub/packages/14.2-x86_64/network/xinetd/xinetd-2.3.15.4-x86_64-1_slonly.txz}

echo " Agent URL: $agent_url"
echo "xinetd URL: $xinetd_url"

agent_filename=$(basename "$agent_url")
agent_version=$(echo "$agent_filename" | cut -d '_' -f2 | cut -d '-' -f1)
pkg_name="checkmk_agent-$(date +'%Y.%m.%d').tgz"
xinetd_filename=$(basename "$xinetd_url")

echo "Agent version: $agent_version"

mkdir -p build
cd build

if [ ! -e "$agent_filename" ]; then
    wget "$agent_url" -O "$agent_filename"
fi

if [ ! -e "$xinetd_filename" ]; then
    wget "$xinetd_url" -O "$xinetd_filename"
    wget -q "${xinetd_url}.md5" -O "${xinetd_filename}.md5"
fi

echo "Extracting $agent_filename"
docker run --rm -v $(pwd):/build -w /build debian:stable-slim dpkg -x "$agent_filename" extracted

Echo "Cleaning extracted file tree"
rm -rf extracted/etc/systemd
rm -rf extracted/usr/lib/check_mk_agent/plugins
rm -rf extracted/usr/share/doc/check-mk-agent/changelog.Debian.gz

echo "Creating Slackware package: $pkg_name"
docker run --rm -v $(pwd):/build -w /build/extracted vbatts/slackware makepkg -l y -c y /build/$pkg_name

cd ..
mkdir -p packages
cp build/$xinetd_filename packages
cp build/${xinetd_filename}.md5 packages
cp build/$pkg_name packages
md5sum packages/$pkg_name > packages/${pkg_name}.md5
