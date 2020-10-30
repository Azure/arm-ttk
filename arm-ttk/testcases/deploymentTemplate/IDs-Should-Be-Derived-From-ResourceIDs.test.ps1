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
$ids = $TemplateObject  | Find-JsonContent -Key *id -Like


# If the "Parameters" property or "Outputs" property is in the lineage, skip check

# If the id points to an object, we can skip, unless:
# the object contains a single property Value, which will will treat as the ID

foreach ($id in $ids) { # Then loop over each object with an ID
    $myIdFieldName = $id.PropertyName
    $myId = $id.$myIdFieldName        

    # these properties are exempt, since they are not actually resourceIds
    $exceptions = @(
        "tenantId",
        "workerSizeId", # Microsoft.Web/serverFarms
        "keyVaultSecretId", # Microsoft.Network/applicationGateways sslCertificates - this is actually a uri created with reference() and concat /secrets/secretname
        "keyId", # Microsoft.Cdn/profiles urlSigningKeys
        "subscriptionId", # Microsoft.Cdn/profiles urlSigningKeys
        "StartingDeviceID", # SQLIaasVMExtension > settings/ServerConfigurationsManagementSettings/SQLStorageUpdateSettings
        "servicePrincipalClientId", # common var name
        "clientId", # Microsoft.BotService - common var name
        "appId", # Microsoft.Insights
        "tenantId", # Common Property name
        "objectId" # Common Property name
    )

    if ($exceptions -contains $myIdFieldName) { # We're checking resource ids, not tenant IDs
        continue
    }
    if ($id.JsonPath -match '^(parameters|outputs)') {
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

    if ($expandedId -isnot [string]) { #if it happens to be an object property, skip it
        continue
    };

    # This sectiom evaluates valid expression syntax for the logic app expressions:
    #   Ref: https://docs.microsoft.com/en-us/azure/logic-apps/workflow-definition-language-functions-reference
    # If found, then it's skipped (success)
    #
    # Check that it uses one of the allowed expressions - can remove variables once Expand-Template does full eval of nested vars
    # REGEX
    # - ^ starts with
    # - 0 or more whitespace
    # - @ 
    # - expression must be 
    #    - option 1: 
    #       - opening {
    #       - any expression in between
    #       - closing }
    #    - option 2
    #       - alpha function name      
    #       - opening paren (
    #       - any expression in between
    #       - closing paren )
    #  Valid expression examples
    #    1  =>   @{coalesce(triggerOutputs().headers?['id'], guid())}
    #    2  =>   @body('Get_email_(V2)_-_Processing')?['id']
    #
    
    $exprMatch0 = "^\s{0,}@((\{.*\})|([\w0-9]+\(.+\)))"
    if ($expandedId -match $exprMatch0  ){
        continue;
    }
    
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
    if ($expandedId -notmatch $exprMatch  ){
            Write-Error "Property: `"$($id.propertyName)`" must use one of the following expressions for an resourceId property:
            $($allowedExpressions -join ',')
            Path: [$($id.JsonPath)]"`
            -TargetObject $id -ErrorId ResourceId.Should.Contain.Proper.Expression
    }
}

