FROM ubuntu-kdb-deps:latest

ENV QHOME /q
ENV PATH ${PATH}:${QHOME}/l64/

RUN mkdir /q

# Install kdb+
COPY q.zip /q
COPY kc.lic /q

WORKDIR /q

RUN \
	unzip q.zip && \
	rm q.zip

COPY qq.sh /root/.bashrc.d

WORKDIR /
