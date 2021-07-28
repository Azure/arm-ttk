<#
.Synopsis
    Ensures Resources do not map ambiguously
.Description
    Ensures resources functions do not map ambiguously.  
    
    ResourceID functions should specify a type and a resource name.

    A ResourceID is considered ambiguious if:

    * The Resource was not found in the template, and no ResourceGroup was specified.
    * The Resource was found in the template with a condition, and no Resource Group was specified.
    * The related Resource contains some but not all of the name segments.
#>
param(
    # The object representation of an Azure Resource Manager template.
    [Parameter(Mandatory, Position = 0)]
    $TemplateObject,

    # The text of an Azure Resource Manager template
    [Parameter(Mandatory, Position = 1)]
    $TemplateText,

    [Parameter(Mandatory, Position = 2)]
    $TemplateFullPath
)

# See #478 a number of scenarios not accounted for in the test.  Going to pull the test and the test cases for now.
continue    

# certain resources are visible at any scope so should be excluded from the test
$proxyResourceTypes = @(
    'Microsoft.Authorization/roleDefinitions',
    'Microsoft.Authorization/policyDefinitions',
    'Microsoft.Authorization/policySetDefinitions'
)

# Find all uses of the function 'ResourceID'

$resourceIdFunctions = $TemplateText | ?<ARM_Template_Function> -FunctionName resourceId

:nextResourceId foreach ($rid in $resourceIdFunctions) {
    $resourceIdParameters = @($rid.Groups["Parameters"] -split ',')

    $foundResourceType = ''
    #    $resourceTypeIndex = -1
    #    $foundApiVersion = ''
    $additionalParameters = @(for ($n = 0 ; $n -lt $resourceIdParameters.Count; $n++) {
            if ($resourceIdParameters[$n] -like '*/*') {
                $foundResourceType = $resourceIdParameters[$n].Replace('(', '').Replace("'", "") # Remove extraneous chars before looking for the resource

                # exclude certain types from the resourceGroupName check
                if ($proxyResourceTypes -notcontains $foundResourceType) {
                    if ($n -eq 0) {
                        # If the resource type is the first parameter
                        $foundResource = # see if we can find a resource with that type.
                        @(Find-JsonContent -InputObject $TemplateObject.resources -Key Type -Value $foundResourceType)
                        if ((-not $foundResource) -or ($foundResource | Where-Object Condition)) { 
                            Write-Error "At least one parameter must preceed the resource type in: $rid" -TargetObject $rid -ErrorId 'ResourceID.Missing.Name'
                            continue nextResourceId
                        }
                    }
                    #$resourceTypeIndex = $n
                }
            }
            elseif ($n) {
                $resourceIdParameters[$n] -replace 
                "^\s{0,}'{0,1}" -replace 
                "\s{0,}'{0,1}$" -replace 
                '\){0,}$'
            }                       
        })

    if ($foundResourceType) {
        $resourceTypeName = $foundResourceType -replace "^\s{0,}'" -replace "\s{0,}'$"        

        if ($foundResourceType.EndsWith('/')) {    
            Write-Error "ResourceType has a trailing slash '$foundResourceType'" -TargetObject $rid -ErrorId 'ResourceID.Trailing.Slash'
        }        

        # Find all resources of this type within the template
        $resourcesOfType = 
        @(Find-JsonContent -InputObject $TemplateObject.resources -Key type -Value $resourceTypeName)            
            
        
        # walk thru each resource of the type
        foreach ($resource in $resourcesOfType) {
            
            $foundParametersInResource = # See if we can find the additional parameters
            @(foreach ($additionalParameter in $additionalParameters) {
                    $resource.name -like "*$additionalParameter*"
                })

            if ($foundParametersInResource.Count -gt 1) {
                # If we found any additional parameters
                # See if we have enough
                if ($foundParametersInResource.Count -lt $additionalParameters.Count) {
                    # If we didn't have enough, we may want to write an error.
                    Write-Error "Resource referencing $rid does not contain all segments of it's resource name" -TargetObject $rid -ErrorId 'ResourceID.Missing.Name'
                }
                else {
                    # but if we did, we can finally feel ok about this resourceID.
                    continue nextResourceID
                }
            }                           
        }

        $resourcesOfSubType = 
        @(Find-JsonContent -InputObject $TemplateObject.resources -Key type -Value @($resourceTypeName -split '/' -ne '')[-1])

        # walk thru each resource of the type
        foreach ($resource in $resourcesOfSubType) {
            $resourceRef = $Resource
            $resourceFullType = @( $resourceRef.ParentObject.type -ne $null)
            [Array]::Reverse($resourceFullType)
            if ($resourceTypeName -ne ($resourceFullType -join '/')) {
                continue
            }
            $foundParametersInResource = # See if we can find the additional parameters
            @(foreach ($additionalParameter in $additionalParameters) {
                    $resource.name -like "*$additionalParameter*"
                })

            if ($foundParametersInResource.Count -gt 1) {
                # If we found any additional parameters
                # See if we have enough
                if ($foundParametersInResource.Count -lt $additionalParameters.Count) {
                    # If we didn't have enough, we may want to write an error.
                    Write-Error "Resource referencing $rid does not contain all segments of it's resource name" -TargetObject $rid -ErrorId 'ResourceID.Missing.Name'
                }
                else {
                    # but if we did, we can finally feel ok about this resourceID.
                    continue nextResourceID
                }
            }                           
        }
    }
}
