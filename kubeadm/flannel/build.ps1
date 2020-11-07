param(
    [switch] $Push, 
    [string] $Image = "sigwindowstools/flannel",
    [string] $cniVersion = "0.8.7"
)

$env:DOCKER_CLI_EXPERIMENTAL = "enabled"
& docker buildx create --name img-builder --use

$env:GOOS = "windows"
$env:GOARCH = "amd64"
& go build -o setup.exe setup.go

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

$output="docker"
if ($Push.IsPresent) {
    $output="registry"
}


$data = Get-Content .\versions.json | ConvertFrom-Json
$data.flannel | %{
    $flannel = $_
    Write-Host "Download 'flanneld.exe' version: $flannel"
    curl -LO https://github.com/coreos/flannel/releases/download/v$flannel/flanneld.exe

    $data.baseimages | %{
        $base = $_.base
        $suffix = $_.suffix
        $dockerfile = $_.dockerfile

        Write-Host "$($Image):$($flannel)$($suffix)"

        $cmd = "docker manifest create $($Image):$($flannel)$($suffix)"

        $_.tags | %{
            $tag = $_

            $cmd = "$cmd --amend $($Image):$($flannel)-$($tag)"

            Write-Host "$($base):$tag"
            & docker buildx build --pull --platform windows/amd64 --output=type=$output -f $dockerfile -t "$($Image):$($flannel)-$($tag)" --build-arg=BASE="$($base):$($tag)" .
        }

        if ($Push.IsPresent) {
            Invoke-Expression $cmd
            & docker manifest push "$($Image):$($flannel)$($suffix)"
        }
    }
}
