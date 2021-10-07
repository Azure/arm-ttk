<#
.Synopsis
    Ensures that resources cannot use an automatic apiVersion
.Description
    Ensures that resources cannot porviders(*).apiVersions, as it can present instability.
#>
param(
# The template text
[Parameter(Mandatory=$true,Position=0)]
[string]
$TemplateText
)

$RULE_ID = "000045"

if ($TemplateText -like '*providers(*).apiVersions*') { # If the template text contains providers(*).apiVersions, fail
    Write-Error "providers().apiVersions is not permitted, use a literal apiVersion" -ErrorId ApiVersion.Using.Providers -TargetObject (Set-RuleID -RuleID $RULE_ID -TargetObject $TemplateText)
}