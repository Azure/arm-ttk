﻿<#
.Synopsis
    Ensures the apiVersions are recent.
.Description
    Ensures the apiVersions of any resources are recent and non-preview.
.Example
    Test-AzTemplate -TemplatePath .\100-marketplace-sample\ -Test apiVersions-Should-Be-Recent
.Example
    .\apiVersions-Should-Be-Recent.test.ps1 -TemplateObject (
        Get-Content ..\..\..\..\100-marketplace-sample\azureDeploy.json | ConvertFrom-Json
    ) -AllAzureResources (
        Get-Content ..\..\cache\AllAzureResources.cache.json | ConvertFrom-Json
    )
      -TestDate (
          [datetime]::ParseExact("31/08/2019", "dd-mm-yy", $null)
    )
#>
param(
    # The resource in the main template
    [Parameter(Mandatory = $true, Position = 0)]
    [PSObject]
    $TemplateObject,

    # All potential resources in Azure (from cache)
    [Parameter(Mandatory = $true, Position = 2)]
    [PSObject]
    $AllAzureResources,

    # Number of days that the apiVersion must be less than
    [Parameter(Mandatory = $false, Position = 3)]
    [int32]
    $NumberOfDays = 730,

    # Test Run Date - date to use when doing comparisons, if not current date (used for unit testing against and old cache)
    [Parameter(Mandatory = $false, Position = 3)]
    [datetime]
    $TestDate = [DateTime]::Now

)


if (-not $TemplateObject.resources) {
    # If we don't have any resources
    # then it's probably a partial template, and there's no apiVersions to check anyway,
    return # so return.
}

# First, find all of the API versions in the main template resources.
$allApiVersions = Find-JsonContent -Key apiVersion -Value * -Like -InputObject $TemplateObject
    




foreach ($av in $allApiVersions) {

    <#
      if the apiVersion is not a direct descendent of the resource skip this one
      some RPs have a property named apiVersion in their properties body
      The following paths would be valid to check
        resources[0].resources[0].apiVersion > this actually translates to apiVersion[0].apiVersion[0].apiVersion after Find-JSONContent
                or
        apiVersion
    #>

    if ($av.jsonPath -ne "apiVersion" -and $av.jsonpath -notmatch "\.apiVersion$") {
        continue
    }

    if ($av.jsonPath -match '\.properties\.apiVersion$') {
        continue
    }

    # Then walk over each object containing an ApiVersion.
    if ($av.ApiVersion -isnot [string]) {
        # If the APIVersion is not a string
        # write an error
        Write-Error "Api Versions must be strings" -TargetObject $av -ErrorId ApiVersion.Not.String
        continue # and continue.
    }

    # Next, resolve the full resource type
    $FullResourceTypes =
    @(
        if ($av.ParentObject) {
            # by walking backwards over the parent resources
            # (since the topmost resource will be the last item in the list)
            for ($i = $av.ParentObject.Count - 1; $i -ge 0; $i--) {
                $parent = $av.ParentObject[$i]
                if (-not $parent.type) { continue }

                # if parent resource type is Microsoft.Resources/deployments, and this is an inner template,
                # do not add the prefix "Microsoft.Resources/deployments" to resource type.
                $expEvalOptions = $parent.properties.expressionEvaluationOptions
                if ($parent.type -eq "Microsoft.Resources/deployments" -and $expEvalOptions) {
                    $scope = $expEvalOptions.scope
                    if ($scope -eq "inner") {
                        continue
                    }
                }
                $parent.type
            }
        }
        $av.type # and adding this resource's type.
    )


    if ($FullResourceTypes -like '*/providers/*') {
        # If we have a provider resources
        $FullResourceTypes = @($FullResourceTypes -split '/')
        if ($av.Name -match "'/{0,}(?<ResourceType>\w+\.\w+)/{0,}'") {
            $FullResourceTypes = @($matches.ResourceType)
        }
        else {
            Write-Warning "Could not identify provider resource for $($FullResourceTypes -join '/')"
            continue
        }
    }

    # To get the full type name, join them all with a slash
    $FullResourceType = @(for ($i = 0; $i -lt $FullResourceTypes.Length; $i++) {
            # If it is not the last segment of a resource type
            if ($i -lt ($FullResourceTypes.Length - 1)) {
                # and it is is not included in a subsequent section
                if (-not ($FullResourceTypes[($i + 1)..$FullResourceTypes.Length] -match "^$($fullResourceTypes[$i])")) {
                    $fullResourceTypes[$i] # include it.
                }            
            }
            else {
                $FullResourceTypes[$i] # Always include the last segment.
            }
        }) -join '/'

    # Now, get the API version as a string
    $apiString = $av.ApiVersion
    $hasDate = $apiString -match "(?<Year>\d{4,4})-(?<Month>\d{2,2})-(?<Day>\d{2,2})"

    if (-not $hasDate) {
        # If we couldn't, write an error

        Write-Error "Api versions must be a fixed date. $FullResourceType is not." -TargetObject $av -ErrorId ApiVersion.Not.Date
        continue # and move onto the next resource
    }
    $apiDate = [DateTime]::new($matches.Year, $matches.Month, $matches.Day) # now coerce the apiVersion into a DateTime

    # Now find all of the valid versions from this API
    $validApiVersions = # This is made a little tricky by the fact that some resources don't directly have an API version
    @(for ($i = $FullResourceTypes.Count - 1; $i -ge 0; $i--) {
            # so we need to walk backwards thru the list of items
            $resourceTypeName = $FullResourceTypes[0..$i] -join '/' # construct the resource type name
            $apiVersionsOfType = $AllAzureResources.$resourceTypeName | # and see if there's an apiVersion.
            Select-Object -ExpandProperty apiVersions |
            Sort-Object -Descending

            if ($apiVersionsOfType) {
                # If there was,
                $apiVersionsOfType # set it and break the loop
                break
            }
        })

    # Create a string of recent or allowed apiVersions for display in the error message
    $recentApiVersions = ""

    #add latest stable apiVersion to acceptable list by default
    $stableApiVersions = $validApiVersions | where-object { $_ -notmatch 'preview' } 
    $latestStableApiVersion = $stableApiVersions | Select-Object -First 1

    $recentApiVersions += "        $latestStableApiVersion`n"


    foreach ($v in $validApiVersions) {

        $hasDate = $v -match "(?<Year>\d{4,4})-(?<Month>\d{2,2})-(?<Day>\d{2,2})"
        $vDate = [DateTime]::new($matches.Year, $matches.Month, $matches.Day)

        # if the apiVersion is "recent" or the latest one add it to the list (note $validApiVersions is sorted)
        # note "recent" means is it new enough that it's allowed by the test
        if ($($TestDate - $vDate).TotalDays -lt $NumberOfDays -or $v -eq $validApiVersions[0]) {
            # TODO: when the only recent versions are a preview version and a non-preview of the same date, $recentApiVersions will only contain the preview
            # due to sorting, which is incorrect
            $recentApiVersions += "        $v`n"
        }
    }
    #if latest stable is already in list, deduplicate
    $recentApiVersions = $recentApiVersions | Select-Object -Unique

    $howOutOfDate = $validApiVersions.IndexOf($av.ApiVersion) # Find out how out of date we are.
    # Is the apiVersion even in the list?
    if ($howOutOfDate -eq -1 -and $validApiVersions) {
        # Removing the error for this now - this is happening with the latest versions and outdated manifests
        # We can assume that if the version is indeed invalid, deployment will fail
        # Write-Error "$fullResourceType is using an invalid apiVersion." -ErrorId ApiVersion.Not.Valid
        # Write-Output "ApiVersion not found for: $fullResourceType and version $($av.apiVersion)"
        # Write-Output "Valid Api Versions found:`n$recentApiVersions"
    }

    if ($av.ApiVersion -like '*-*-*-*') {
        # If it's a preview or other special variant, e.g. 2016-01-01-preview

        $moreRecent = $validApiVersions[0..$howOutOfDate] # see if there's a more recent non-preview version.
        if ($howOutOfDate -gt 0 -and $moreRecent -notlike '*-*-*-*') {
            Write-Error "$FullResourceType uses a preview version ( $($av.apiVersion) ) and there are more recent versions available." -TargetObject $av -ErrorId ApiVersion.Preview.Not.Recent
            Write-Output "Valid Api Versions:`n$recentApiVersions"
        }

        # the sorted array doesn't work perfectly so 2020-01-01-preview comes before 2020-01-01
        # in this case if the dates are the same, the non-preview version should be used
        if ($howOutOfDate -eq 0 -and $validApiVersions.Count -gt 1) {
            # check the second apiVersion and see if it matches the preview one
            $nextApiVersion = $validApiVersions[1]
            # strip the qualifier on the apiVersion and see if it matches the next one in the sorted array
            $truncatedApiVersion = $($av.apiVersion).Substring(0, $($av.ApiVersion).LastIndexOf("-"))
            if ($nextApiVersion -eq $truncatedApiVersion) {
                Write-Error "$FullResourceType uses a preview version ( $($av.apiVersion) ) and there is a non-preview version for that apiVersion available." -TargetObject $av -ErrorId ApiVersion.Preview.Version.Has.NonPreview
                Write-Output "Valid Api Versions:`n$recentApiVersions"
            }
        }
    }

    # Finally, check how long it's been since the ApiVersion's date
    $timeSinceApi = $TestDate - $apiDate
    if (($timeSinceApi.TotalDays -gt $NumberOfDays) -and ($howOutOfDate -gt 0)) {
        # if the used apiVersion is the second in the list, check to see if the first in the list is the same preview version (due to sorting)
        # for example: "2017-12-01-preview" and "2017-12-01" - the preview is sorted first so we think we're out of date
        $nonPreviewVersionInUse = $false
        if ($howOutOfDate -eq 1) {
            $trimmedApiVersion = $validApiVersions[0].ToString().Substring(0, $validApiVersions[0].ToString().LastIndexOf("-"))
            $nonPreviewVersionInUse = ($trimmedApiVersion -eq $av.apiVersion)
        }
        if (-not $nonPreviewVersionInUse) {            
            if ($($av.ApiVersion) -eq $latestStableApiVersion) {     
                #break from loop to avoid throwing error when using latest stable API version           
                break
            }

            # If it's older than two years, and there's nothing more recent
            Write-Error "Api versions must be the latest or under $($NumberOfDays / 365) years old ($NumberOfDays days) - API version $($av.ApiVersion) of $FullResourceType is $([Math]::Floor($timeSinceApi.TotalDays)) days old" -ErrorId ApiVersion.OutOfDate -TargetObject $av
            Write-Output "Valid Api Versions:`n$recentApiVersions"
        }
    }

    if (! $validApiVersions.Contains($av.apiVersion)) {
        Write-Warning "The apiVersion $($av.apiVersion) was not found for the resource type: $FullResourceType"
    }

}
