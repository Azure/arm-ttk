<#
.Synopsis
    Ensures Deployment Resources Must not use DebugSetting
.Description
    Ensures resources of type Microsoft.Resources/deployments do not have 
    their DebugSetting property set (to a value other than 'None').

    DebugSetting may also be an object.
    If this is the case, this object must not have a logDetail property, 
    or the DetailLevel property must be set to 'None'.  
#>
param(
# The Template Object
[Parameter(Mandatory)]
[PSObject]
$TemplateObject
)

$deploymentResources = $TemplateObject.resources | 
    Find-JsonContent -Key type -Value 'Microsoft.Resources/deployments'


foreach ($dr in $deploymentResources) {
    $dbg = $dr.properties.debugSetting.detailLevel
    if ($dbg) {
        if ($dbg -is [string] -and  $dbg -ne 'None') {
            Write-Error "Deployment Resources must have no DebugSettings property, or must set it to 'None'" -TargetObject $dr -ErrorId "Deployment.Resource.Has.DebugSetting"
        }
        elseif (
            $dbg -isnot [string] -and 
            $dbg -and 
            $dbg -ne 'None'
        ) {
            Write-Error "Deployment Resources must have no DebugSettings.logDetail property, or must set it to 'None'" -TargetObject $dr -ErrorId "Deployment.Resource.Has.LogDetail"
        }
    }
}