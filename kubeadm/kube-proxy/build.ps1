param(
    [string]$image = "sigwindowstools/kube-proxy",
    [switch]$push
)

[int]$minMajor = 1
[int]$minMinor = 19
[int]$minBuild = 0

$env:DOCKER_CLI_EXPERIMENTAL = "enabled"
& docker buildx create --name img-builder --use

$output="docker"
if ($push.IsPresent) {
    $output="registry"
}


function buildKubeProxy([string]$tag) 
{
    Write-Host "-------------- $tag ---------------" -ForegroundColor White

    $versions = Get-Content ".\buildconfig.json" | ConvertFrom-Json
    $base = $versions.baseimage
    $cmd = "docker manifest create $($image):$tag"
    foreach($map in $versions.tagsMap) 
    {
        $cmd = "$cmd --amend $($image):$tag-$($map.target)"
        Write-Host "Build $($image):$tag-$($map.target)" -ForegroundColor Green
        & docker buildx build --pull --platform windows/amd64 --output=type=$output -f Dockerfile -t "$($image):$tag-$($map.target)" --build-arg=BASE="$($base):$($map.source)" --build-arg=flannelVersion=$flannel .
    }

    if ($push.IsPresent)
    {
        Write-Host "Create manifest for $($image):$tag" -ForegroundColor Yellow
        Write-Host $cmd
        Invoke-Expression $cmd

        foreach($map in $versions.tagsMap) 
        {
            $manifest = $(docker manifest inspect "$($base):$($map.source)" -v) | ConvertFrom-Json
            $platform = $manifest.Descriptor.platform
            $folder = ("docker.io/$($image):$tag" -replace "/", "_") -replace ":", "-"
            $img = ("docker.io/$($image):$tag-$($map.target)" -replace "/", "_") -replace ":", "-"
            Write-Host "Update '~/.docker/manifests/$folder/$img'"
            $manifest = Get-Content "~/.docker/manifests/$folder/$img" | ConvertFrom-Json
            $manifest.Descriptor.platform = $platform
            $manifest | ConvertTo-Json -Depth 10 -Compress | Set-Content "~/.docker/manifests/$folder/$img"
        }

        & docker manifest push "$($image):$tag"
    }

    Write-Host
}

$tags = (curl -L k8s.gcr.io/v2/kube-proxy/tags/list | ConvertFrom-Json).tags
foreach($tag in $tags)
{
    if ($tag -match "^v(\d+)\.(\d+)\.(\d+)$")
    {
        [int]$major = $Matches[1]
        [int]$minor = $Matches[2]
        [int]$build = $Matches[3]

        if (($major -gt $minMajor) -or ($major -eq $minMajor -and $minor -gt $minMinor) -or ($major -eq $minMajor -and $minor -eq $minMinor -and $build -ge $minBuild))
        {
            buildKubeProxy -tag $tag
        }
    }
}
