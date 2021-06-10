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

# Walk over each potential control type.
foreach ($controlType in $ControlTypesWithHideExisting) {

    # then walk thru all controls of that type.
    foreach ($foundControl in (Find-JsonContent -Key type -Value $controlType -InputObject $CreateUIDefinitionObject) ) {
        
        $options = $foundControl.options

        # if hideExisting != True (options are the property may be missing or explicitly set to false)
        if ($options.HideExisting -ne $true) {
            # determine the output values
            $outputValues = @($CreateUIDefinitionObject.parameters.outputs.psobject.properties | Select-Object -ExpandProperty Value)
            if (-not ($outputValues -like "*$($foundControl.Name)*.ResourceGroup*" )) { # error if there is no 'ResourceGroup' output.
                Write-Error "Control Named '$($foundControl.name)' must output the resourceGroup property when hideExisting is false." -TargetObject $foundControl -ErrorId Missing.Output.ResourceGroup
            }
            if (-not ($outputValues -like "*$($foundControl.Name)*.NewOrExisting*" )) { # error if there is no 'NewOrExisting' output.
                Write-Error "Control Named '$($foundControl.name)' must output the newOrExisting property when hideExisting is false." -TargetObject $foundControl -ErrorId Missing.Output.NewOrExisting
            }
        }        
    }
}



