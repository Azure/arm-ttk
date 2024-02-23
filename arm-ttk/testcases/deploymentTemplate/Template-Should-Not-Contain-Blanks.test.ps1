<#
.Synopsis
    TODO: summary of test
.Description
    TODO: describe this test
#>

param(
    [Parameter(Mandatory = $true)]
    [string]
    $TemplateText,

    [Parameter(Mandatory = $true)]
    [PSObject]
    $TemplateObject,

    # Some properties can be empty for readability
    [string[]]    
    $PropertiesThatCanBeEmpty = @('resources',
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
                            'AzureMonitor', # Microsoft.Insights/VMDiagnosticsSettings
                            'requiredDataConnectors' #Microsoft.SecurityInsights/AlertRuleTemplates
    ),

    # Some properties can be empty within a given resource.
    # The key is the full resource type name, and the value is a list of JSON paths to acceptable blanks.
    # For instance, a value of "properties" would allow blanks in any subproperty named properties
    # A value of "properties.settings" would allow blanks in any subproperty of settings.
    [Collections.IDictionary]
    $ResourcePropertiesThatCanBeEmpty = @{
        "Microsoft.Web/sites/config" = "properties";
        "Microsoft.Insights/workbooks" = "properties.serializedData"
    }
)

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


if ($emptyItems) {  # If we found empty items
    # Do what we need to in order to determine if they are "really" empty

    # Find any instances of these properties within the document.
    $foundPropertiesThatCanBeEmpty = @(Find-JsonContent -Key "(?>$($PropertiesThatCanBeEmpty -join '|'))" -Match  -InputObject $TemplateObject)

    # Find the short or long name for each resource type
    $resourceTypesThatCanBeEmpty = @($ResourcePropertiesThatCanBeEmpty.Keys) + @(
        foreach ($k in $ResourcePropertiesThatCanBeEmpty.Keys) {
            @($k -split '/')[-1]
        }
    )


    # Find all resources of interest
    $foundResourcesThatCanContainBlanks = 
        @(Find-JsonContent -Key "type" -Value "(?>$($resourceTypesThatCanBeEmpty -join '|'))" -Match -InputObject $TemplateObject | 
        Foreach-Object { 
            $jsonMatch = $_
        
            $resourceTypeBlankPaths = # Find the properties within this resource that can be blank
                @(if (-not $ResourcePropertiesThatCanBeEmpty[$jsonMatch.type]) { # If the type is not a full name
                    # Walk the hierarchy to find the full name
                    $fullTypeList = @($jsonMatch.type) + @($jsonMatch.Parent | Where-Object Type | Select-Object -ExpandProperty Type)
                    [Array]::Reverse($fullTypeList) 
                    if (-not $ResourcePropertiesThatCanBeEmpty[$fullTypeList -join '/']) { # If this was a resource we did not care about
                        return # return
                    } else {
                        $ResourcePropertiesThatCanBeEmpty[$fullTypeList -join '/']
                    }
                } else {
                    $ResourcePropertiesThatCanBeEmpty[$jsonMatch.type]
                })

            foreach ($blankPath in $resourceTypeBlankPaths) { # Each acceptable blank path is appended to the JSON path of the return object
                Resolve-JSONContent -JSONText $TemplateText -JSONPath "$($jsonMatch.JSONPath).$blankPath" # and resolved.
            }
        })

    $resourceBlankRange = # All resolved blank ranges are turned into a list of indexes
        @(
            foreach ($_ in $foundResourcesThatCanContainBlanks) {
                for ($i = $_.Index; $i -lt $_.Index + $_.Length; $i++) {
                    $i
                }
            }
        )


    :nextBlank foreach ($emptyItem in $emptyItems) {
        if ($emptyItem.Index -in $resourceBlankRange) { continue } # If the blank is within a range of acceptable indexes, continue.
        $nearbyContext = [Regex]::new('"(?<PropertyName>[^"]{1,})"\s{0,}:', "RightToLeft").Match($TemplateText, $emptyItem.Index)
        if ($nearbyContext -and $nearbyContext.Success) {
            $emptyPropertyName = $nearbyContext.Groups["PropertyName"].Value
            # exceptions
            if ($PropertiesThatCanBeEmpty -contains $emptyPropertyName) { # If the property was one we said could be empty, 
                continue # continue to the next blank.
            }
            foreach ($potentialException in $foundPropertiesThatCanBeEmpty) { # Otherwise, walk over each potential exception found
                if ($potentialException.psobject.properties -and # and see if it has this property.
                    $potentialException.psobject.properties[$emptyPropertyName]) {
                    continue nextBlank # If so we will continue to the next blank.
                }
            }
            # userAssigned Identity can have an expression for the property name
            # it could also be a literal resourceId
            if ($emptyPropertyName -match "\s{0,}\[" -or              # an expression starts with [
                $emptyPropertyName -match "\s{0,}\/subscriptions\/"){ # a resourceId starts with /subscriptions/
                continue
            }
            $lineNumber = @($lineBreaks | Where-Object { $_.Index -lt $emptyItem.Index }).Count + 1
            $targetObject = $emptyItem.PsObject.Copy()
            $targetObject | Add-Member -MemberType NoteProperty -Name lineNumber -Value $lineNumber
            Write-Error "Empty property: $emptyItem" -TargetObject $targetObject
        } 
    }
}
