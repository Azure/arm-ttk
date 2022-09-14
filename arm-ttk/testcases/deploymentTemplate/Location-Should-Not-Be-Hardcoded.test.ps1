<#
.Synopsis
    Ensures that the location is not hardcoded.
.Description
    Attempts to ensures that location is not hardcoded, by:

    * Ensure the location parameter is not a literal
    * Ensuring that references to resourceGroup().location are contained within parameters
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

# Determine where the parameters section is within the JSON
$paramsSection  = Resolve-JSONContent -JSONPath 'parameters' -JSONText $TemplateText
$deployments    = Find-JsonContent -InputObject $TemplateObject -Key type -Value Microsoft.Resources/deployments |  # Find any deployments
    Resolve-JSONContent -JSONText $TemplateText -JSONPath { $_.JsonPath -replace '\.type$' }      # and then resolve the resource they are in.

$ignoredRanges = 
    @() + @(
        if ($paramsSection.Index -and $paramsSection.Length) {
            $paramsSection.Index..($paramsSection.Index + $paramsSection.Length)
        }
    ) + @(
        foreach ($deployment in $deployments) {
            $deployment.Index..($deployment.Index + $deployment.Length)
        }
    )

$LocationRegex = '(?>resourceGroup|deployment)\(\).location'


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
    if ($locationParameter.defaultValue -ne $null -and 
        $locationParameter.defaultValue -notmatch $LocationRegex) {
        Write-Error "The location parameter of nested templates must not have a defaultValue property. It is `"$($locationParameter.defaultValue)`"" -ErrorId Location.Parameter.DefaultValuePresent -TargetObject $parameter
    }   
}

# Now check that the rest of the template doesn't use [resourceGroup().location] or [deployment().location] except in the params section
$foundResourceGroupLocations = [Regex]::Matches($TemplateText, $LocationRegex, 'IgnoreCase')
    
foreach ($spotFound in $foundResourceGroupLocations) {
    if ($spotFound.Index -in $ignoredRanges) {
        continue
    }
    Write-Error "$TemplateFileName must use the location parameter, not resourceGroup().location or deployment().location (except when used as a default value in the main template)" -ErrorId Location.Parameter.Should.Be.Used -TargetObject $parameter
}



$resourceLocationProperties = Find-JsonContent -InputObject $TemplateObject -Key location |
    Where-Object JSONPath -match 'resources\[\d+\]\.location'

foreach ($locationProp in $resourceLocationProperties) {
    if (($locationProp.location -ne 'global') -and -not (
        $locationProp.location | ?<ARM_Template_Expression>
    )) {
        Write-Error "Location value of '$($locationProp.location)' on resource '$($locationProp.name)' must be an expression or 'global'." -TargetObject $locationProp -ErrorId Location.Hardcoded
    }
}
