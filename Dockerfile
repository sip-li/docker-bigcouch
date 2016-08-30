FROM centos:6

MAINTAINER joe <joe@valuphone.com>

LABEL   os="linux" \
        os.distro="centos" \
        os.version="6"

LABEL   lang.name="erlang" \
        lang.version="R14B01"

LABEL   app.name="bigcouch" \
        app.version="1.1.1"

ENV     ERLANG_VERSION=R14B01 \
        BIGCOUCH_VERSION=1.1.1

ENV     HOME=/opt/bigcouch \
        PATH=/opt/bigcouch/bin:$PATH

COPY    setup.sh /tmp/setup.sh
RUN     /tmp/setup.sh

COPY    entrypoint /usr/bin/entrypoint

ENV     BIGCOUCH_LOG_LEVEL=info

VOLUME  ["/var/lib/bigcouch"]

EXPOSE  4369 5984 5986 11500-11999

# USER    bigcouch

WORKDIR /opt/bigcouch

CMD     ["/usr/bin/entrypoint"]
