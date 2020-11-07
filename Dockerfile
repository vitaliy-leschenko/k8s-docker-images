ARG tag="ltsc2019"
ARG baseImage="mcr.microsoft.com/windows/servercore"
ARG flannelVersion="0.13.0"
ARG cniVersion="0.8.7"
ARG golangTag=windowsservercore-1809

FROM golang:${golangTag} as builder
ADD setup.go build/
RUN go build -o build/setup.exe build/setup.go

FROM ${baseImage}:${tag}
SHELL ["powershell", "-NoLogo", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ARG flannelVersion
ARG cniVersion

RUN mkdir -force C:\k\flannel; \
  pushd C:\k\flannel; \
  curl.exe -LO https://github.com/coreos/flannel/releases/download/v${env:flannelVersion}/flanneld.exe

ADD hns.psm1 /k/flannel
COPY --from=builder /gopath/build/setup.exe /k/flannel/setup.exe

RUN mkdir C:\cni; \
  pushd C:\cni; \
  curl.exe -Lo cni.tgz https://github.com/containernetworking/plugins/releases/download/v${env:cniVersion}/cni-plugins-windows-amd64-v${env:cniVersion}.tgz; \
  tar -xf cni.tgz; \
  rm cni.tgz

RUN mkdir C:\utils; \
  curl.exe -Lo C:\utils\wins.exe https://github.com/rancher/wins/releases/download/v0.0.4/wins.exe; \
  curl.exe -Lo C:\utils\yq.exe https://github.com/mikefarah/yq/releases/download/2.4.1/yq_windows_amd64.exe; \
  "[Environment]::SetEnvironmentVariable('PATH', $env:PATH + ';C:\utils', [EnvironmentVariableTarget]::Machine)"
