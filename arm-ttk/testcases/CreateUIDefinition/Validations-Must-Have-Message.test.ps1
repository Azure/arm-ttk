<#
.Synopsis
    Ensures that validations in CreateUIDefinition controls have message in each item.
.Description
    Ensures that validations in CreateUIDefinition controls have message in each item.
#>
param(
    # The contents of CreateUIDefintion, converted from JSON.
    [Parameter(Mandatory = $true, Position = 0)]
    [PSObject]
    $CreateUIDefinitionObject
)

# Find any item property in CreateUIDefinition that uses validations
$constraints = @($CreateUIDefinitionObject | 
    Find-JsonContent -Key validations -Value * -Like)
foreach ($cobj in $constraints) {
    # Walk thru each thing we find.
    # First we need to find the control
    $parent = $cobj.ParentObject[0]
    $messageKey = 'message'

    foreach ($item in $cobj.validations) {
        if (-not $item.psobject.properties.Item($messageKey)) {
            # Find the item name
            $key = foreach ($object_properties in $item.PsObject.Properties) {
                if ($object_properties.Name -ne $messageKey) { 
                    $object_properties.Name; break
                }
            }
            Write-Error -Message "Validations property in $($parent.Name) is missing message for $($key)." -ErrorId Validations.Must.Have.Message -TargetObject $parent #error.
        }
    }
}