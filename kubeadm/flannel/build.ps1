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

            $_.tags | %{
                $manifest = $(docker manifest inspect $($base):$($tag) -v) | ConvertFrom-Json
                $osVersion = $manifest.Descriptor.platform.'os.version'
                & docker manifest annotate --os-version $osVersion $($Image):$($flannel)$($suffix) $($Image):$($flannel)-$($tag)
            }

            & docker manifest push "$($Image):$($flannel)$($suffix)"
        }
    }
}
