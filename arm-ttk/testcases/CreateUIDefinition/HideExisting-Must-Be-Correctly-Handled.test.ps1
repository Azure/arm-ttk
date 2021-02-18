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

# A list of control types that can have a "HidExisting" property.
[string[]]
$ControlTypesWithHideExisting = @(
    'Microsoft.Storage.StorageAccountSelector',
    'Microsoft.Network.PublicIpAddressCombo',
    'Microsoft.Network.VirtualNetworkCombo'
)
)


$foundHideExisting = $false           # Keep track of if we found "HideExisting"
$needsResourceGroupInOutputs = $false # and keep track on if we need 'ResourceGroup' in Outputs.
# Walk over each potential control type.
foreach ($controlType in $ControlTypesWithHideExisting) {
    # then walk thru all controls of that type.
    foreach ($foundControl in (Find-JsonContent -Key type -Value $controlType -InputObject $CreateUIDefinitionObject) ) {
        $needsResourceGroupInOutputs = $true  # If we found any of these controls, we need a 'ResourceGroup'
        if ($foundControl.psobject.properties['hideExisting']) { # If any we found hideExisting, note that.
            $foundHideExisting = $true
            if ($foundControl.hideExisting) {
                $needsResourceGroupInOutputs = $false
            }
        }
    }
}

if ($needsResourceGroupInOutputs) { # If we needed a 'ResourceGroup'/'NewOrExisting' output
    # determine the output names
    $outputNames = @($CreateUIDefinitionObject.parameters.outputs.psobject.properties | Select-Object -ExpandProperty Name)
    if (-not ($outputNames -like '*ResourceGroup*' )) { # error if there is no 'ResourceGroup' output.
        Write-Error "An output named like '*ResourceGroup*' must be an output when resources of type '$controlType' are used" -TargetObject $foundControl -ErrorId Missing.Output.ResourceGroup
    }
    if (-not ($outputNames -like '*NewOrExisting*' )) { # error if there is no 'NewOrExisting' output.
        Write-Error "An output named like '*newOrExisting*' must be an output when resources of type '$controlType' are used" -TargetObject $foundControl -ErrorId Missing.Output.NewOrExisting
    }
}

