param(
    [switch] $Push, 
    [string] $Image = "sigwindowstools/flannel"
)

$env:DOCKER_CLI_EXPERIMENTAL = "enabled"
& docker buildx create --name img-builder --use

$output="docker"
if ($Push.IsPresent) {
    $output="registry"
}

$data = Get-Content .\versions.json | ConvertFrom-Json
$data.flannel | %{
    $flannel = $_

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
            & docker buildx build --pull --platform windows/amd64 --output=type=$output -f $dockerfile -t "$($Image):$($flannel)-$($tag)" --build-arg=BASE="$($base):$($tag)" --build-arg=flannelVersion=$flannel .
        }

        if ($Push.IsPresent) {
            Invoke-Expression $cmd

            & ls ~/.docker -a -l

            $_.tags | %{
                $manifest = $(docker manifest inspect $($base):$($tag) -v) | ConvertFrom-Json
                $platform = $manifest.Descriptor.platform

                $folder = ("docker.io/$($Image):$($flannel)$($suffix)" -replace "/", "_") -replace ":", "-"
                $img = ("docker.io/$($Image):$($flannel)-$($tag)" -replace "/", "_") -replace ":", "-"

                Write-Host "Update '~/.docker/manifests/$folder/$img'"

                $manifest = Get-Content "~/.docker/manifests/$folder/$img" | ConvertFrom-Json
                $manifest.Descriptor.platform = $platform

                $manifest | ConvertTo-Json -Depth 10 -Compress | Set-Content "~/.docker/manifests/$folder/$img"
            }

            & docker manifest push "$($Image):$($flannel)$($suffix)"
        }
    }
}
