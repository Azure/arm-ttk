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

$RULE_ID_START = "BP-6-"

$resourcesWithDependencies = $TemplateObject.resources | 
    Find-JsonContent -Key dependsOn -Value '*' -Like

foreach ($dependentResource in $resourcesWithDependencies) {
    if ($dependentResource.DependsOn -match '^\s{0,}\[') {
        if ($dependentResource.DependsOn -match '^\s{0,}\[\s{0,}if\s{0,}\(') {
            Write-Error "Resource Dependencies must not start with if()" -TargetObject (Set-RuleID -RuleIDStart $RULE_ID_START -CurrentRuleNumber 1 -TargetObject $dependentResource) -ErrorId "Resource.DependsOn.Conditional"    
        }
        if ($dependentResource.DependsOn -match '^\s{0,}\[\s{0,}concat\s{0,}\(' -and 
            -not ($dependentResource.DependsOn | ?<ARM_Template_Function> -FunctionName copyIndex)
        ) {
            Write-Error "Depends On Must not start with [concat(" -TargetObject (Set-RuleID -RuleIDStart $RULE_ID_START -CurrentRuleNumber 2 -TargetObject $dependentResource) -ErrorId "Resource.DependsOn.StartsWithConcat"
        }
    }
}
