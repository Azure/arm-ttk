$myName = $MyInvocation.MyCommand.ScriptBlock.File | Split-Path -Leaf
$targetFileName = $myName -replace '\.unit',''
$testDir = Join-Path (Join-Path (Split-Path $PSScriptRoot) 'arm-ttk') 'testcases'
$targetFile = 
    foreach ($file in Get-ChildItem $testDir -Recurse) {
        if ($file.Name -eq $targetFileName) { 
            $ExecutionContext.SessionState.InvokeCommand.GetCommand($file.FullName, 'ExternalScript'); break 
        } 
    }

if (-not $targetFile) {
    Write-Error "Test $targetFileName not found"
    return
}


$Results = 
    & $targetFile -TemplateText @'
{
    "Variables":  {
        "dataDisks":  {
            "diskSizeGB":  1023,
            "writeAcceleratorEnabled":  false,
            "id":  null,
            "name":  null
        }
    }
}
'@ *>&1

foreach ($r in $results) {
    if ($r -isnot [Management.Automation.ErrorRecord]) {
        throw "Expected Errors"
    }
    if ($r.ToString() -notlike 'Empty property found on line:*') {
        throw "Error Message was unexpected: $r"
    }
}