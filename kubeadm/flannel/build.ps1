param(
    [string] $BuildID = "", 
    [switch] $Push, 
    [string] $Image = "test/flannel",
    [string] $cniVersion = "0.8.7"
)

$env:GOOS = "windows"
$env:GOARCH = "amd64"
& go build -o setup.exe setup.go

$id = "";
if ($BuildID -ne "") {
    $id = "-$BuildID"
}

Write-Host "Download 'CNI' version: $cniVersion"
New-Item cni -Type Directory -Force | Out-Null
pushd cni
curl -Lo cni.tgz https://github.com/containernetworking/plugins/releases/download/v$cniVersion/cni-plugins-windows-amd64-v$cniVersion.tgz
tar -xf cni.tgz
rm cni.tgz
popd

Write-Host "Download utils..."
New-Item utils -Type Directory -Force | Out-Null
pushd utils
curl -Lo wins.exe https://github.com/rancher/wins/releases/download/v0.0.4/wins.exe
curl -Lo yq.exe https://github.com/mikefarah/yq/releases/download/2.4.1/yq_windows_amd64.exe
popd

$data = Get-Content .\versions.json | ConvertFrom-Json
$data.flannel | %{
    $flannel = $_
    Write-Host "Download 'flanneld.exe' version: $flannel"
    curl -LO https://github.com/coreos/flannel/releases/download/v$flannel/flanneld.exe

    $data.baseimages | %{
        $base = $_.base
        $suffix = $_.suffix
        $dockerfile = $_.dockerfile

        Write-Host "sigwindowstools/flannel:$($flannel)$($suffix)"

        $cmd = "docker manifest create $($Image):$($flannel)$($suffix)"

        $_.tags | %{
            $tag = $_

            $cmd = "$cmd --amend $($Image):$($flannel)-$($tag)$($id)"

            Write-Host "$($base):$tag"
            & docker build -f $dockerfile -t "$($Image):$($flannel)-$($tag)$($id)" --build-arg=flannelVersion=$flannel --build-arg=baseImage=$base --build-arg=tag=$tag .
            if ($Push.IsPresent) {
                & docker push "$($Image):$($flannel)-$($tag)$($id)"
            }
        }

        if ($Push.IsPresent) {
            Invoke-Expression $cmd
            & docker manifest push "$($Image):$($flannel)$($suffix)"
        }
    }
}