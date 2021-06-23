<#
.Synopsis
    Ensures the apiVersions are recent (when used in reference functions).
.Description
    Ensures the apiVersions of any resources used within reference functions are recent and non-preview.
#>
param(
    # The resource in the main template
    [Parameter(Mandatory = $true, Position = 0)]
    [string]
    $TemplateText,

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

$foundReferences = $TemplateText | 
    ?<ARM_Template_Function> -FunctionName 'reference|list\w{1,}'

foreach ($foundRef in $foundReferences) {
    
    $hasApiVersion = $foundRef.Value | ?<ARM_API_Version> -Extract # Find the api version
    if (-not $hasApiVersion) { continue } # if we don't have one, continue.
    $apiVersion = $hasApiVersion.0 
    $hasResourceId = $foundRef.Value | ?<ARM_Template_Function> -FunctionName resourceId
    $hasVariable   = $foundRef.value | ?<ARM_Variable> | Select-Object -First 1
    $potentialResourceType = ''

    if ($hasResourceId) {       
        $parameterSegments= @($hasResourceId.Groups["Parameters"].value -split '[(),]' -ne '' -replace "^\s{0,}'" -replace "'\s{0,}$")
        $potentialResourceType = ''
        $resourceTypeStarted = $false
        $potentialResourceType = @(foreach ($seg in $parameterSegments) {
            if ($seg -like '*/*') {
                $seg
            }
        }) -join '/'
    } elseif ($hasVariable) {
        $foundResource = Find-JsonContent -Key name -Value "*$($hasVariable.Value)*" -InputObject $TemplateObject -Like |
            Where-Object JSONPath -Like *Resources* | 
            Select-Object -First 1

        $typeList = @(@($foundResource) + @($foundResource.ParentObject) | Where-Object Type | Select-Object -ExpandProperty Type)
        [Array]::Reverse($typeList)
        $potentialResourceType = $typeList -join '/'
    }
    
    if (-not $potentialResourceType) { continue }
    
    $apiDate = [DateTime]::new($hasApiVersion.Year, $hasApiVersion.Month, $hasApiVersion.Day) # now coerce the apiVersion into a DateTime

    $validApiVersions = @($AllAzureResources.$potentialResourceType | # and see if there's an apiVersion.
        Select-Object -ExpandProperty apiVersions |
        Sort-Object -Descending)

    if (-not $validApiVersions) { 
        $potentialResourceTypes = @($potentialResourceType -split '/')
        for ($i = ($potentialResourceTypes.Count - 1); $i -ge 1; $i--) {
            $potentialType = $potentialResourceTypes[0..$i] -join '/'
            if ($AllAzureResources.$potentialType) {
                $validApiVersions = @($AllAzureResources.$potentialType | # and see if there's an apiVersion.
                    Select-Object -ExpandProperty apiVersions |
                    Sort-Object -Descending)            
                break
            }
        }
        if (-not $validApiVersions) { 
            continue
        }
    }

    # Create a string of recent or allowed apiVersions for display in the error message
    $recentApiVersions = ""

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

    $howOutOfDate = $validApiVersions.IndexOf($ApiVersion) # Find out how out of date we are.
    # Is the apiVersion even in the list?
    if ($howOutOfDate -eq -1 -and $validApiVersions) {
        # Removing the error for this now - this is happening with the latest versions and outdated manifests
        # We can assume that if the version is indeed invalid, deployment will fail
        Write-Error "$potentialResourceType is using an invalid apiVersion." -ErrorId ApiReference.Version.Not.Valid -TargetObject $foundRef
        Write-Output "ApiVersion not found for: $($foundRef.Value) and version $($av.apiVersion)" 
        Write-Output "Valid Api Versions found $potentialResourceType :`n$recentApiVersions"
    }

    if ($ApiVersion -like '*-*-*-*') {
        # If it's a preview or other special variant, e.g. 2016-01-01-preview

        $moreRecent = $validApiVersions[0..$howOutOfDate] # see if there's a more recent non-preview version. 
        if ($howOutOfDate -gt 0 -and $moreRecent -notlike '*-*-*-*') {
            Write-Error "$($foundRef.Value)  uses a preview version ( $($apiVersion) ) and there are more recent versions available." -TargetObject $foundRef -ErrorId ApiReference.Version.Preview.Not.Recent
            Write-Output "Valid Api Versions $potentialResourceType :`n$recentApiVersions"
        }

        # the sorted array doesn't work perfectly so 2020-01-01-preview comes before 2020-01-01
        # in this case if the dates are the same, the non-preview version should be used
        if ($howOutOfDate -eq 0 -and $validApiVersions.Count -gt 1){
            # check the second apiVersion and see if it matches the preview one
            $nextApiVersion = $validApiVersions[1]
            # strip the qualifier on the apiVersion and see if it matches the next one in the sorted array
            $truncatedApiVersion = $($apiVersion).Substring(0, $($ApiVersion).LastIndexOf("-"))
            if ($nextApiVersion -eq $truncatedApiVersion){
                Write-Error "$($foundRef.Value) uses a preview version ( $($apiVersion) ) and there is a non-preview version for that apiVersion available." -TargetObject $foundRef -ErrorId ApiReference.Version.Preview.Version.Has.NonPreview
                Write-Output "Valid Api Versions for $potentialResourceType :`n$recentApiVersions"                
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
            $nonPreviewVersionInUse = ($trimmedApiVersion -eq $apiVersion)
        }
        if (-not $nonPreviewVersionInUse) {
            # If it's older than two years, and there's nothing more recent
            Write-Error "Api versions must be the latest or under $($NumberOfDays / 365) years old ($NumberOfDays days) - API version used by:`n            $($foundRef.Value)`n        is $([Math]::Floor($timeSinceApi.TotalDays)) days old" -ErrorId ApiReference.Version.OutOfDate -TargetObject $foundRef
            Write-Output "Valid Api Versions for $potentialResourceType :`n$recentApiVersions"
        }
    }
}
