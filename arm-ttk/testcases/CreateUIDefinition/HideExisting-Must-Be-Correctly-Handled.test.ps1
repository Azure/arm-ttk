<#
.Synopsis
    Ensures the HideExisting property is correctly handled
.Description
    Ensures the HideExisting property is paired with the outputs 'ResourceGroup' and 'NewOrExisting'
#>
param(
# The CreateUIDefinition Object
[Parameter(Mandatory=$true,Position=0)]
[PSObject]
$CreateUIDefinitionObject,

[string[]]
$ControlTypesWithHideExisting = @(
    'Microsoft.Storage.StorageAccountSelector',
    'Microsoft.Network.PublicIpAddressCombo',
    'Microsoft.Network.VirtualNetworkCombo'
)
)


$foundHideExisting = $false

$needsResourceGroupInOutputs = $false
foreach ($controlType in $ControlTypesWithHideExisting) {
    
    foreach ($foundControl in $CreateUIDefinitionObject | Find-JsonContent -Key type -Value $controlType) {
        $needsResourceGroupInOutputs = $true
        if ($foundControl.psobject.properties['hideExisting']) {
            $foundHideExisting = $true
        }        
        if ($foundControl.hideExisting) { continue }

        # In the future, we want to pair this to it's output in mainTemplate and find out if it is used within a conditional.
    }
}

if ($needsResourceGroupInOutputs) {
    $outputNames = @($CreateUIDefinitionObject.parameters.outputs.psobject.properties | Select-Object -ExpandProperty Name)
    if (-not ($outputNames -like '*resourcegroup*' )) {
        Write-Error "An output named like '*ResourceGroup*' must be an output when resources of type '$controlType' are used" -TargetObject $foundControl -ErrorId Missing.Output.ResourceGroup
    }
    if (-not ($outputNames -like '*neworexisting*' )) {
        Write-Error "An output named like '*newOrExisting*' must be an output when resources of type '$controlType' are used" -TargetObject $foundControl -ErrorId Missing.Output.NewOrExisting
    }
}

