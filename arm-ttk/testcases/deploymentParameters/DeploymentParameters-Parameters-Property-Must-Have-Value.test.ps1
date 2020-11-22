<#
.Synopsis
    Ensures that parameters have a value
.Description
    Ensures that all parameters have a property 'value'
#>
param(
    # The Template Object
    [Parameter(Mandatory = $true, Position = 0)]
    [PSObject]
    $TemplateObject
)

Write-Debug $TemplateObject.parameters
foreach ($p in $TemplateObject.parameters.psobject.properties) {
    
    # If the parameter name starts with two underscores,
    if ($p.Name -like '__*') { continue } # skip it.

    # check if the property exist on the hashtable Value property for the key 'value'
    if ( -not $p.Value.PsObject.Properties.match('value').Count ) {
        Write-Error -ErrorId Parameters.Parameter.Missing.Value -Message "'$($p.Name)' must have a property 'value'" -TargetObject $p.Value 
        continue
    }
}