<#
.Synopsis
    Ensures that the ManagedIdentityExtension is not used.
.Description
    Ensures that the ManagedIdentityExtension is not anywhere within template resources.
#>
param(
[Parameter(Mandatory=$true,Position=0)]
[PSObject]
$TemplateObject
)

$RULE_ID_START = "BP-13-"

$resourcesJson = $TemplateObject.resources  | ConvertTo-Json -Depth 100  

if ($resourcesJson -match 'ManagedIdentityExtension') {
    Write-Error "Managed Identity Extension must not be used" -ErrorId ManagedIdentityExtension.Was.Used -TargetObject (Set-RuleID -RuleIDStart $RULE_ID_START -RuleNumber 1)
}