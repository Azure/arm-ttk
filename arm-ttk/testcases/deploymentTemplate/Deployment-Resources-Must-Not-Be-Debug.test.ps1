<#
.Synopsis
    Ensures Deployment Resources Must not use DebugSetting
.Description
    Ensures resources of type Microsoft.Resources/deployments do not have 
    their DebugSetting property set (to a value other than 'None').
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
    if ($dr.DebugSetting -and $dr.DebugSetting -ne 'None') {
        Write-Error "Deployment Resources must have no DebugSettings property, or must set it to 'None'" -TargetObject $dr -ErrorId "Deployment.Resource.Has.DebugSetting"
    }
}  