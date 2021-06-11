<#
.Synopsis
    Ensures DependsOn does not use if()
.Description
    Ensures resources with DependsOn do not use 'if' in their subexpression.
#>
param(
# The Template Object
[Parameter(Mandatory)]
[PSObject]
$TemplateObject
)

$resourcesWithDependencies = $TemplateObject.resources | 
    Find-JsonContent -Key dependsOn -Value '*' -Like

foreach ($dependentResource in $resourcesWithDependencies) {
    if ($dependentResource.DependsOn -match '^\s{0,}\[') {
        if ($dependentResource.DependsOn -like '*if(*') {
            Write-Error "Resource Dependencies must not use if()" -TargetObject $dependentResource -ErrorId "Resource.DependsOn.Conditional"    
        }
        if ($dependentResource.DependsOn -match '^\s{0,}\[\s{0,}concat\s{0,}\(' -and 
            -not ($dependentResource.DependsOn | ?<ARM_Template_Function> -FunctionName copyIndex)
        ) {
            Write-Error "Depends On Must not start with [concat(" -TargetObject $dependentResource -ErrorId "Resource.DependsOn.StartsWithConcat"
        }
    }
}
