ARG BASE="mcr.microsoft.com/powershell:nanoserver-1809"
ARG cniVersion="0.8.7"
ARG flannelVersion="0.13.0"

FROM --platform=linux/amd64 golang as setup
ENV GOOS=windows
ENV GOARCH=amd64
ADD setup.go build/
RUN go build -o build/setup.exe build/setup.go

FROM --platform=linux/amd64 ubuntu as bins
ARG flannelVersion
ARG cniVersion

WORKDIR /flannel 
RUN curl -LO https://github.com/coreos/flannel/releases/download/v${flannelVersion}/flanneld.exe

WORKDIR /cni
RUN curl -Lo cni.tgz https://github.com/containernetworking/plugins/releases/download/v${cniVersion}/cni-plugins-windows-amd64-v${cniVersion}.tgz
RUN tar -xf cni.tgz
RUN rm cni.tgz

WORKDIR /utils
RUN curl -Lo C:\utils\wins.exe https://github.com/rancher/wins/releases/download/v0.0.4/wins.exe
RUN curl -Lo C:\utils\yq.exe https://github.com/mikefarah/yq/releases/download/2.4.1/yq_windows_amd64.exe

FROM $BASE

ADD hns.psm1 /k/flannel/hns.psm1
COPY --from=setup /gopath/build/setup.exe /k/flannel/setup.exe
COPY --from=bins /flannel/flanneld.exe /k/flannel/flanneld.exe
COPY --from=bins /cni /cni
COPY --from=bins /utils /utils

ENV PATH="C:\Program Files\PowerShell;C:\utils;C:\Windows\system32;C:\Windows;"
