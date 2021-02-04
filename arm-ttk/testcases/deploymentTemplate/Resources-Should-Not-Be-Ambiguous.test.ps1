<#
.Synopsis
    Ensures Resources do not map ambiguously
.Description
    Ensures resources functions do not map ambiguously.  ResourceID functions should specify a type and a 
#>
param(
# The object representation of an Azure Resource Manager template.
[Parameter(Mandatory,Position=0)]
$TemplateObject,

# The text of an Azure Resource Manager template
[Parameter(Mandatory,Position=1)]
$TemplateText
)

# Find all uses of the function 'ResourceID'
$resourceIdFunctions = $TemplateText | ?<ARM_Template_Function> -FunctionName resourceId

:nextResourceId foreach ($rid in $resourceIdFunctions) {
    $resourceIdParameters = @($rid.Groups["Parameters"] -split ',')

    $foundResourceType = ''
    $foundApiVersion = ''
    for ($n = 0 ;$n -lt $resourceIdParameters.Count;$n++) {
        if ($resourceIdParameters[$n] -like '*/*') {
            $foundResourceType = $resourceIdParameters[$n]
                    
            if ($n -eq 0) { # If the resource type is the first parameter
                $foundResource = # see if we can find a resource with that type.
                    Find-JsonContent -InputObject $TemplateObject.resources -Key Type -Value $resourceIdParameters[$n]
                if (-not $foundResource -or 
                    $foundResource.condition) 
                { 
                    Write-Error "At least one parameter must preceed the resource type" -TargetObject $rid -ErrorId 'ResourceID.Missing.Name'
                    continue nextResourceId
                }

            }
        }
        

        if (-not $foundApiVersion) { 
            $foundApiVersion = $resourceIdParameters[$n] | ?<ARM_API_Version>
        }
    }

    if ($foundResourceType) {
        $resourceTypeName = $foundResourceType -replace "^\s{0,}'" -replace "\s{0,}'$"

        if ($foundResourceType -match "/'\s{0,}$") {
            Write-Error "ResourceType has a trailing slash '$foundResourceType'" -TargetObject $rid -ErrorId 'ResourceID.Trailing.Slash'
        }
    }
}
