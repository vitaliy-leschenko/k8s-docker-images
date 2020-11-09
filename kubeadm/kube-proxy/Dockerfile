ARG BASE="mcr.microsoft.com/powershell:nanoserver-1809"
ARG k8sVersion="v1.19.3"

FROM --platform=linux/amd64 ubuntu as bins
ARG k8sVersion

RUN apt-get update && apt-get install curl -y

WORKDIR /kube-proxy
RUN curl -sLO https://dl.k8s.io/${k8sVersion}/bin/windows/amd64/kube-proxy.exe

WORKDIR /utils
RUN curl -Lo wins.exe https://github.com/rancher/wins/releases/download/v0.0.4/wins.exe
RUN curl -Lo yq.exe https://github.com/mikefarah/yq/releases/download/2.4.1/yq_windows_amd64.exe

FROM $BASE

COPY --from=bins /kube-proxy /k/kube-proxy
COPY --from=bins /utils /utils

ENV PATH="C:\Program Files\PowerShell;C:\utils;C:\Windows\system32;C:\Windows;"
USER ContainerAdministrator
