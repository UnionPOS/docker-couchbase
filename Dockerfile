FROM couchbase/server:enterprise-7.1.6

# Add any additional configuration or files here, if needed.
# For example, to copy a custom configuration file:
# COPY my-couchbase.conf /opt/couchbase/etc/couchbase.conf

# Install necessary tools
RUN apt-get update && apt-get install -y unzip curl wget runit

# http://smarden.org/runit/useinit.html#sysv - at some point the script
# runsvdir-start was moved/renamed to this odd name, so we put it back
# somewhere sensible. This appears to be necessary for Ubuntu > 16.04
RUN if [ ! -x /usr/sbin/runsvdir-start ]; then \
        cp -a /etc/runit/2 /usr/sbin/runsvdir-start; \
    fi

# Expose the necessary ports (default Couchbase ports):
EXPOSE 8091 8092 8093 11210 18091 18092 18093 11207

# If you need to set environment variables:
# ENV SOME_VAR=some_value

COPY scripts/docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["couchbase-server"]
