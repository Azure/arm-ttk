<#
.Synopsis
    TODO: summary of test
.Description
    TODO: describe this test
#>

param(
    [Parameter(Mandatory = $true, Position = 0)] #not mandatory for case of an empty resource array
    [PSObject]$TemplateObject
)

$RULE_ID = "000047"

foreach ($r in $TemplateObject.Resources) {
    foreach ($resource in @(@($r) + $r.ParentResources)) { 
        if ($resource.Location) {
            $location = "$($resource.location)".Trim()
            if ($location -notmatch '^\[.*\]$' -and $location -ne 'global') {
                Write-Error "Resource $($resource.Name) Location must be an expression or 'global'" -TargetObject (Set-RuleID -RuleID $RULE_ID -TargetObject $resource)
            }
        }
    }
}
