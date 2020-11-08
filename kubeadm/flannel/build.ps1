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
foreach ($flannel in $data.flannel)
{
    foreach ($template in $data.baseimages)
    {
        $base = $template.base
        $suffix = $template.suffix
        $dockerfile = $template.dockerfile

        Write-Host "$($Image):$($flannel)$($suffix)"

        $cmd = "docker manifest create $($Image):$($flannel)$($suffix)"

        foreach ($tag in $template.tags)
        {
            $cmd = "$cmd --amend $($Image):$($flannel)-$($tag)"

            Write-Host "$($base):$tag"
            & docker buildx build --pull --platform windows/amd64 --output=type=$output -f $dockerfile -t "$($Image):$($flannel)-$($tag)" --build-arg=BASE="$($base):$($tag)" --build-arg=flannelVersion=$flannel .
        }

        if ($Push.IsPresent) {
            Write-Host $cmd
            Invoke-Expression $cmd

            foreach ($tag in $template.tags)
            {
                [string] $data = $(docker manifest inspect "$($base):$($tag)" -v)
                $manifest = $data | ConvertFrom-Json
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
