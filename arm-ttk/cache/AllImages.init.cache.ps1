#TODO - don't think this cache is ever used
exit

$MyFile= $MyInvocation.MyCommand.ScriptBlock.File  
$myName = $MyFile | Split-Path -Leaf 
$myName = $myName -replace '\.init\.cache\.ps1'
$myRoot = $MyFile | Split-Path
$MyOutputFile = Join-Path $myRoot "$myName.cache.json"


$images = az vm image list --all -o json  | ConvertFrom-Json
if (-not $images) {
    Write-Error "Could not list providers.  You may not be logged in."
    return
}

$images | Sort-Object Urn | ConvertTo-Json -Depth 100 | Set-Content $MyOutputFile 
