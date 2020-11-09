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
    foreach($map in $versions.tagsMap) 
    {
        Write-Host "Build $($image):$tag-$($map.target)" -ForegroundColor Green
        & docker buildx build --pull --platform windows/amd64 --output=type=$output -f Dockerfile -t "$($image):$tag-$($map.target)" --build-arg=BASE="$($base):$($map.source)" --build-arg=flannelVersion=$flannel .
    }

    Write-Host "todo: Create manifest for $($image):$tag" -ForegroundColor Yellow
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
