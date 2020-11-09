param(
    [switch] $push, 
    [string] $image = "sigwindowstools/flannel"
)

$env:DOCKER_CLI_EXPERIMENTAL = "enabled"
& docker buildx create --name img-builder --use

$output="docker"
if ($push.IsPresent) {
    $output="registry"
}

$config = Get-Content .\buildconfig.json | ConvertFrom-Json
$base = $config.baseimage
foreach ($flannel in $config.flannel)
{
    Write-Host "Build images for flannel version: $flannel"

    $cmd = "docker manifest create $($image):$flannel"
    foreach($map in $config.tagsMap) 
    {
        $cmd = "$cmd --amend $($image):$flannel-$($map.target)"
        Write-Host "Build $($image):$flannel-$($map.target)" -ForegroundColor Green
        & docker buildx build --pull --platform windows/amd64 --output=type=$output -f Dockerfile -t "$($image):$flannel-$($map.target)" --build-arg=BASE="$($base):$($map.source)" --build-arg=flannelVersion=$flannel .
    }

    if ($push.IsPresent)
    {
        Write-Host "Create manifest for $($image):$flannel" -ForegroundColor Yellow
        Write-Host $cmd
        Invoke-Expression $cmd

        foreach($map in $config.tagsMap) 
        {
            $manifest = $(docker manifest inspect "$($base):$($map.source)" -v) | ConvertFrom-Json
            $platform = $manifest.Descriptor.platform
            $folder = ("docker.io/$($image):$flannel" -replace "/", "_") -replace ":", "-"
            $img = ("docker.io/$($image):$flannel-$($map.target)" -replace "/", "_") -replace ":", "-"
            Write-Host "Update '~/.docker/manifests/$folder/$img'"
            $manifest = Get-Content "~/.docker/manifests/$folder/$img" | ConvertFrom-Json
            $manifest.Descriptor.platform = $platform
            $manifest | ConvertTo-Json -Depth 10 -Compress | Set-Content "~/.docker/manifests/$folder/$img"
        }

        & docker manifest push "$($image):$flannel"
    }

    Write-Host
}
