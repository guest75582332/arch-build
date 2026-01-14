FROM archlinux:latest@sha256:417aa2d3e8e4cc8377360a94bf48ae1ed38e593cbecfcb34feb16d57e3efa1b5

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN date
RUN pacman -Syu --noconfirm
RUN pacman -S base-devel git python --noconfirm
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"] 
