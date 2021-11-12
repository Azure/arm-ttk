<#
.Synopsis
    TODO: summary of test
.Description
    TODO: describe this test
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$TemplateText,

    [Parameter(Mandatory = $true)]
    [PSObject]$TemplateObject,

    [Parameter(Mandatory = $true)]
    [string]$TemplateFileName,

    [switch]$IsMainTemplate
)

# initialize TemplateTextWithoutLocationParameter for the case where there is no parameter object in the template (test is below)
$TemplateWithoutLocationParameter = $TemplateText 

# First, create a copy of the template object
$TemplateObjectCopy = $templateText | ConvertFrom-Json

# Then remove the location property if it exists
if ($TemplateObjectCopy.parameters.psobject -ne $null) {
    $TemplateObjectCopy.parameters.psobject.properties.remove('location')
    # and turn it back into JSON.
    $TemplateWithoutLocationParameter = $TemplateObjectCopy | 
    ConvertTo-Json -Depth 100       

    # Now get the location parameter 
    $locationParameter = $templateObject.parameters.location
}
# All location parameters must be of type "string" in the parameter declaration
if ($locationParameter -ne $null -and $locationParameter.type -ne "string") {
    Write-Error "The location parameter must be a 'string' type in the parameter declaration `"$($locationParameter.type)`"" -ErrorId Location.Parameter.TypeMisMatch -TargetObject $parameter
}

# In mainTemplate:
# If there is a parameter named "location" then
#   if that parameter has a defaultValue, it must be the expression [resourceGroup().location] 
if ($IsMainTemplate) { 
    if ($locationParameter.defaultValue -and 
        "$($locationParameter.defaultvalue)".Trim() -ne '[resourceGroup().location]' -and 
        "$($locationParameter.defaultvalue)".Trim() -ne 'global' -and 
        "$($locationParameter.defaultvalue)".Trim() -ne '[deployment().location]') {
        Write-Error "The defaultValue of the location parameter in the main template must not be a specific location. `
                         The default value must be [resourceGroup().location], [deployment().location] or 'global'. It is `"$($locationParameter.defaultValue)`"" -ErrorId Location.Parameter.Hardcoded -TargetObject $parameter
    }
    # In all other templates:
    # if the parameter named "location" exists, it must not have a defaultValue property
    # Note that Powershell will count an empty string (which should fail the test) as null if not explictly tested, so we check for it
}
else {
    if ($locationParameter.defaultValue -ne $null) { 
        Write-Error "The location parameter of nested templates must not have a defaultValue property. It is `"$($locationParameter.defaultValue)`"" -ErrorId Location.Parameter.DefaultValuePresent -TargetObject $parameter
    }   
}

# TODO: removing the check for deployment().location as bicep codegens this for modules at subscription scope.
# we'll need to modify the test to allow it on deployment resources (and catch it in other places (which is not common))
# see: https://github.com/Azure/arm-ttk/issues/346
# Now check that the rest of the template doesn't use [resourceGroup().location] or deployment().location
if ($TemplateWithoutLocationParameter -like '*resourceGroup().location*' # -or
    # $TemplateWithoutLocationParameter -like '*deployment().location*'
) {
    # If it did, write an error
    Write-Error "$TemplateFileName must use the location parameter, not resourceGroup().location or deployment().location (except when used as a default value in the main template)" -ErrorId Location.Parameter.Should.Be.Used -TargetObject $parameter
}

