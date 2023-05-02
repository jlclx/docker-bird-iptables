FROM archlinux AS builder
ENV bird_version=2.13
RUN pacman -Sy --noconfirm wget make gcc bison m4 flex ncurses readline iptables
RUN wget https://bird.network.cz/download/bird-${bird_version}.tar.gz
RUN tar -xzvf bird-${bird_version}.tar.gz
WORKDIR bird-${bird_version}
RUN ./configure
RUN make
RUN mkdir /build
RUN mv bird /build
RUN mv birdc /build

FROM gcr.io/distroless/static:debug
COPY --from=builder /build/bird /usr/local/bin/_bird
COPY --from=builder /build/birdc /usr/local/bin/_birdc
COPY --from=builder /usr/bin/iptables /usr/bin/iptables
COPY --from=builder /usr/bin/iptables-save /usr/bin/iptables-save

COPY --from=builder /usr/lib/libreadline.so.8 /usr/lib/libreadline.so.8
COPY --from=builder /usr/lib/libncursesw.so.6 /usr/lib/libncursesw.so.6
COPY --from=builder /usr/lib/libxtables.so.12 /usr/lib/libxtables.so.12
COPY --from=builder /usr/lib/libip4tc.so.2 /usr/lib/libip4tc.so.2
COPY --from=builder /usr/lib/libip6tc.so.2 /usr/lib/libip6tc.so.2
COPY --from=builder /usr/lib/xtables/* /usr/lib/xtables/
COPY --from=builder /usr/lib/libc.so.6 /usr/lib/libc.so.6
COPY --from=builder /usr/lib/ld-linux-x86-64.so.2 /usr/lib/ld-linux-x86-64.so.2

RUN ["/busybox/sh", "-c", "mkdir -p /usr/local/bird"]
RUN ["/busybox/sh", "-c", "mkdir -p /usr/local/var/run"]
RUN ["/busybox/sh", "-c", "mkdir -p /etc/iptables"]

RUN ["/busybox/sh", "-c", "echo '#! /busybox/sh' >> /usr/local/bin/bird"]
RUN ["/busybox/sh", "-c", "echo '/usr/lib/ld-linux-x86-64.so.2 /usr/local/bin/_bird $@' >> /usr/local/bin/bird"]
RUN ["/busybox/sh", "-c", "chmod +x /usr/local/bin/bird"]

RUN ["/busybox/sh", "-c", "echo '#! /busybox/sh' >> /usr/local/bin/birdc"]
RUN ["/busybox/sh", "-c", "echo '/usr/lib/ld-linux-x86-64.so.2 /usr/local/bin/_birdc $@' >> /usr/local/bin/birdc"]
RUN ["/busybox/sh", "-c", "chmod +x /usr/local/bin/birdc"]

RUN ["/busybox/sh", "-c", "echo '#! /busybox/sh' >> /usr/local/bin/iptables"]
RUN ["/busybox/sh", "-c", "echo '/usr/lib/ld-linux-x86-64.so.2 /usr/bin/iptables $@' >> /usr/local/bin/iptables"]
RUN ["/busybox/sh", "-c", "chmod +x /usr/local/bin/iptables"]

RUN ["/busybox/sh", "-c", "echo '#! /busybox/sh' >> /usr/local/bin/iptables-save"]
RUN ["/busybox/sh", "-c", "echo '/usr/lib/ld-linux-x86-64.so.2 /usr/bin/iptables-save $@' >> /usr/local/bin/iptables-save"]
RUN ["/busybox/sh", "-c", "chmod +x /usr/local/bin/iptables-save"]

ENTRYPOINT ["/busybox/sh"]
CMD ["/usr/local/bin/bird", "-d"]
