FROM ubuntu:18.04

# Install dependencies:
#  runit: for container process management
#  wget: for downloading .deb
#  python-httplib2: used by CLI tools
#  chrpath: for fixing curl, below
#  tzdata: timezone info used by some N1QL functions
# Additional dependencies for system commands used by cbcollect_info:
#  lsof: lsof
#  lshw: lshw
#  sysstat: iostat, sar, mpstat
#  net-tools: ifconfig, arp, netstat
#  numactl: numactl
RUN apt-get update && \
  apt-get install -yq curl runit wget python-httplib2 chrpath tzdata \
  lsof lshw sysstat net-tools numactl zip unzip && \
  apt-get autoremove && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ARG CB_VERSION="7.0.2"
ARG CB_RELEASE_URL="https://packages.couchbase.com/releases"
ARG CB_PACKAGE="couchbase-server-enterprise_${CB_VERSION}-ubuntu18.04_amd64.deb"

# this checksum is for 6.5.0
#ARG CB_SHA256="712aeeeed364d5364c55fb8f21b65bd1610f067a4cb4c851c4b69df4689c3f1d"

# this checksum is for 7.0.2
ARG CB_SHA256="12357b7d0fe63da5785194633164ede10cb00ca9d2ee98e144e3d120a5b0587d"

ENV PATH=$PATH:/opt/couchbase/bit:/opt/couchbase/bin/tools:/opt/couchbase/bin/install

# Create Couchbase user with UID 1000 (necessary to match default
# boot2docker UID)
RUN groupadd -g 1000 couchbase && useradd couchbase -u 1000 -g couchbase -M

# Install couchbase
RUN export INSTALL_DONT_START_SERVER=1 && \
  wget -N $CB_RELEASE_URL/$CB_VERSION/$CB_PACKAGE && \
  echo "$CB_SHA256  $CB_PACKAGE" | sha256sum -c - && \
  dpkg -i ./$CB_PACKAGE && rm -f ./$CB_PACKAGE

# http://smarden.org/runit/useinit.html#sysv - at some point the script
# runsvdir-start was moved/renamed to this odd name, so we put it back
# somewhere sensible. This appears to be necessary for Ubuntu > 16.04
RUN if [ ! -x /usr/sbin/runsvdir-start ]; then \
        cp -a /etc/runit/2 /usr/sbin/runsvdir-start; \
    fi

# Add runit script for couchbase-server
COPY scripts/run /etc/service/couchbase-server/run
RUN chown -R couchbase:couchbase /etc/service

# Add dummy script for commands invoked by cbcollect_info that
# make no sense in a Docker container
COPY scripts/dummy.sh /usr/local/bin/
RUN ln -s dummy.sh /usr/local/bin/iptables-save && \
  ln -s dummy.sh /usr/local/bin/lvdisplay && \
  ln -s dummy.sh /usr/local/bin/vgdisplay && \
  ln -s dummy.sh /usr/local/bin/pvdisplay

# Fix curl RPATH
RUN chrpath -r '$ORIGIN/../lib' /opt/couchbase/bin/curl

# Add bootstrap script
COPY scripts/docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["couchbase-server"]

# 8091: Couchbase Web console, REST/HTTP interface
# 8092: Views, queries, XDCR
# 8093: Query services (4.0+)
# 8094: Full-text Search (4.5+)
# 8095: Analytics (5.5+)
# 8096: Eventing (5.5+)
# 11207: Smart client library data node access (SSL)
# 11210: Smart client library/moxi data node access
# 11211: Legacy non-smart client library data node access
# 18091: Couchbase Web console, REST/HTTP interface (SSL)
# 18092: Views, query, XDCR (SSL)
# 18093: Query services (SSL) (4.0+)
# 18094: Full-text Search (SSL) (4.5+)
# 18095: Analytics (SSL) (5.5+)
# 18096: Eventing (SSL) (5.5+)
# EXPOSE 8091 8092 8093 8094 8095 8096 11207 11210 11211 18091 18092 18093 18094 18095 18096
VOLUME /opt/couchbase/var

