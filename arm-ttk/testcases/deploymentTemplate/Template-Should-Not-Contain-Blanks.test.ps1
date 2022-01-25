<#
.Synopsis
    TODO: summary of test
.Description
    TODO: describe this test
#>

param(
    [Parameter(Mandatory = $true)]
    [string]
    $TemplateText
)

$MarketplaceWarning = $true

# Check for any text to remove empty property values - PowerShell handles empty differently in objects so check the JSON source (i.e. text)
# Empty strings, arrays, objects and null property values are not allowed, they have specific meaning in a declarative model
# the part of the expression '(?<=:)' is a back reference that means the expression must follow a colon, 
#   but the colon is not part of the match
#   this ensures that the $PropertiesThatCanBeEmpty exceptions don't include the colon in the property name when we search
#   the nearby context below

$colon = "(?<=:)\s{0,}" # this a back reference for a colon followed by 0 to more whitespace

$emptyItems = @([Regex]::Matches($TemplateText, "${colon}\{\s{0,}\}")) + # Empty objects
              @([Regex]::Matches($TemplateText, "${colon}\[\s{0,}\]")) + # empty arrays
              @([Regex]::Matches($TemplateText, "${colon}`"\s{0,}`"")) + # empty strings
              @([Regex]::Matches($TemplateText, "${colon}null"))

# TODO: This test will flag things like json('null') - that needs to be fixed before we add a check for null
# @([Regex]::Matches($TemplateText, 'null')) # null json property value

$lineBreaks = [Regex]::Matches($TemplateText, "`n|$([Environment]::NewLine)")

# Some properties can be empty for readability
$PropertiesThatCanBeEmpty = 'resources',
                            'outputs',
                            'variables',
                            'parameters',
                            'functions',
                            'properties',
                            'template',
                            'defaultValue', # enables optional parameters
                            'accessPolicies',  # keyVault requires this
                            'value', # Microsoft.Resources/deployments - passing empty strings to a nested deployment
                            'promotionCode', # Microsoft.OperationsManagement/soltuions/plan object
                            'inputs', # Microsoft.Portal/dashboard
                            'notEquals', # Microsoft.Authorization/policyDefinitions policyRule'
                            'clientId', # Microsoft.ContainerService/managedClusters.properties.servicePrincipalProfile
                            'allowedCallerIpAddresses', # Microsoft.Logic/workflows Access Control
                            'workerPools', # Microsoft.Web/hostingEnvironments
                            'AzureMonitor' # Microsoft.Insights/VMDiagnosticsSettings

if ($emptyItems) {
    foreach ($emptyItem in $emptyItems) {
        $nearbyContext = [Regex]::new('"(?<PropertyName>[^"]{1,})"\s{0,}:', "RightToLeft").Match($TemplateText, $emptyItem.Index)
        if ($nearbyContext -and $nearbyContext.Success) {
            $emptyPropertyName = $nearbyContext.Groups["PropertyName"].Value
            # exceptions
            if ($PropertiesThatCanBeEmpty -contains $emptyPropertyName) {
                continue
            }
            # userAssigned Identity can have an expression for the property name
            # it could also be a literal resourceId
            if ($emptyPropertyName -match "\s{0,}\[" -or              # an expression starts with [
                $emptyPropertyName -match "\s{0,}\/subscriptions\/"){ # a resourceId starts with /subscriptions/
                continue
            }
            $lineNumber = @($lineBreaks | ? { $_.Index -lt $emptyItem.Index }).Count + 1
            $targetObject = $emptyItem.PsObject.Copy()
            $targetObject | Add-Member -MemberType NoteProperty -Name lineNumber -Value $lineNumber
            Write-TtkMessage -MarketplaceWarning $MarketplaceWarning "Empty property: $emptyItem found on line: $lineNumber" -TargetObject $targetObject
        } 
    }
}
