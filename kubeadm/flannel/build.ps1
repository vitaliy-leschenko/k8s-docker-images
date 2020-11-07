set-location ./kubeadm/flannel

$env:GOOS = "windows"
$env:GOARCH = "amd64"
& go build -o setup.exe setup.go

ls

#& docker.exe build -f .\Dockerfile -t "flannel:1809" --build-arg=flannelVersion=0.13.0 --build-arg=tag=1809 .