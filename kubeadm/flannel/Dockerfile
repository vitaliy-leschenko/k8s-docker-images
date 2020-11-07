ARG tag="ltsc2019"

FROM mcr.microsoft.com/windows/servercore:${tag}
SHELL ["powershell", "-NoLogo", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ADD hns.psm1 /k/flannel
ADD setup.exe /k/flannel
ADD flanneld.exe /k/flannel
ADD cni /cni
ADD utils /utils

ENV PATH="C:\Program Files\PowerShell;C:\utils;C:\Windows\system32;C:\Windows;"