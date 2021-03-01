<#
.Synopsis
    Ensures that all IDs use the resourceID() function.
.Description
    Ensures that all IDs use the resourceID() function, or resolve to parameters or variables that use the ResourceID() function.
.Example
    Test-AzTemplate -TemplatePath .\100-marketplace-sample\ -Test IDs-Should-Be-Derived-From-ResourceIDs
.Example
    .\IDs-Should-Be-Derived-From-ResourceIDs.test.ps1 -TemplateObject (Get-Content ..\..\..\unit-tests\IDs-Should-Be-Derived-From-ResourceIDs.json -Raw | ConvertFrom-Json)
#>
param(
# The template object (the contents of azureDeploy.json, converted from JSON)
[Parameter(Mandatory=$true,Position=0)]
$TemplateObject
)

# First, find all objects with an ID property in the MainTemplate.
$ids = $TemplateObject.resources | Find-JsonContent -Key *id -Like


# If the "Parameters" property or "Outputs" property is in the lineage, skip check

# If the id points to an object, we can skip, unless:
# the object contains a single property Value, which will will treat as the ID

foreach ($id in $ids) { # Then loop over each object with an ID
    $myIdFieldName = $id.PropertyName
    $myId = $id.$myIdFieldName

    # these properties are exempt, since they are not actually resourceIds
    $exceptions = @(
        "appId",                       # Microsoft.Insights
        "clientId",                    # Microsoft.BotService - common var name
        "DataTypeId",                  # Microsoft.OperationalInsights/workspaces/dataSources
        "defaultMenuItemId",           # Microsoft.Portal/dashboards - it's a messy resource
        "keyVaultSecretId",            # Microsoft.Network/applicationGateways sslCertificates - this is actually a uri created with reference() and concat /secrets/secretname
        "keyId",                       # Microsoft.Cdn/profiles urlSigningKeys
        "objectId",                    # Common Property name
        "menuId",                      # Microsoft.Portal/dashboards
        "policyDefinitionReferenceId", # Microsft.Authorization/policySetDefinition unique Id used when setting up a PolicyDefinitionReference
        "servicePrincipalClientId",    # common var name
        "StartingDeviceID",            # SQLIaasVMExtension > settings/ServerConfigurationsManagementSettings/SQLStorageUpdateSettings
        "subscriptionId",              # Microsoft.Cdn/profiles urlSigningKeys
        "SyntheticMonitorId",          # Microsoft.Insights/webtests
        "targetProtectionContainerId", # Microsoft.RecoveryServices/vaults/replicationFabrics/replicationProtectionContainers/replicationProtectionContainerMappings (yes really)
        "targetWorkerSizeId",          # Microsoft.Web/serverFarms (later apiVersions)
        "tenantId",                    # Common Property name
        "timezoneId",                  # Microsoft.SQL/managedInstances
        "vlanId",                      # Unique Id to establish peering when setting up an ExpressRoute circuit
        "workerSizeId"                 # Microsoft.Web/serverFarms (older apiVersions)
    )

    if ($exceptions -contains $myIdFieldName) { # We're checking resource ids, not tenant IDs
        continue
    }
    if ($id.JsonPath -match '^(parameters|outputs)') {
        continue
    }

    # Skip this check if the property is within a logic app
    if ( $id.ParentObject.type -match '^microsoft\.logic/workflows$' ) {
        continue
    }

    # skip resourceId check within tags #274
    if ( $id.JSONPath -match "\.(tags)\.($myIdFieldName)" ) { 
        continue 
    }

    if ($myId -isnot [string] -and ($myId -as [float] -eq $null)) {
        if (-not $myId.Value) {
            continue
        } else {
            $myId = $myId.Value
            if ($myId -isnot [string]) {
                continue
            }
        }
    }

    # $myId = "$($id.id)".Trim() # Grab the actual ID,
    if (-not $myId) {
        Write-Error "Blank ID Property found: $($id | Out-String)" -TargetObject $id -ErrorId ResourceId.Is.Missing
        continue
    }
    $expandedId = Expand-AzTemplate -Expression $myId -InputObject $TemplateObject -Exclude Parameters # then expand it.

    # these are allowed for resourceIds
    $allowedExpressions = @(
        "extensionResourceId",
        "resourceId",
        "subscriptionResourceId",
        "tenantResourceId",
        "if",
        "parameters",
        "reference",
        "variables",
        "subscription",
        "guid"
    )

    # Check that it uses one of the allowed expressions - can remove variables once Expand-Template does full eval of nested vars
    # REGEX
    # - 0 or more whitespace
    # - [ to make sure it's an expression
    # - expression must be parameters|variables|*resourceId
    # - 0 or more whitespace
    # - opening paren (
    # - 0 or more whitepace
    # - single quote on parameters and variables (resourceId first parameters may not be a literal string)
    #
    $exprMatch = "\s{0,}\[\s{0,}($($allowedExpressions -join '|' ))\s{0,}\(\s{0,}"

    if ($expandedId -is [string] -and ` #if it happens to be an object property, skip it
        $expandedId -notmatch $exprMatch  ){
            Write-Error "Property: `"$($id.propertyName)`" must use one of the following expressions for an resourceId property:
            $($allowedExpressions -join ',')" `
             -TargetObject $id -ErrorId ResourceId.Should.Contain.Proper.Expression
    }
}
