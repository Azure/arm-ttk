$MyFile= $MyInvocation.MyCommand.ScriptBlock.File  
$myName = $MyFile | Split-Path -Leaf 
$myName = $myName -replace '\.init\.cache\.ps1'
$myRoot = $MyFile | Split-Path
$MyOutputFile = Join-Path $myRoot "$myName.cache.json"


$azEnv = Get-AzEnvironment
if (-not $azEnv) {
    Write-Error "Could not list providers.  You may not be logged in."
    return
}

$azEnv | Sort-Object Name | ConvertTo-Json -Depth 100 | Set-Content $MyOutputFile 
