<#
.Synopsis
    Ensures Deployment Templates do not use hardcoded URLs
.Description
    Ensures Deployment Templates do not use Hardcoded URLs found in the AllEnvironments cache.
#>
param(
# The template text.
[string]
$TemplateText,

# The list of hosts that are not allowed.
[string[]]
$DisallowedHosts = 
    @(
        "management.core.windows.net",
        "gallery.azure.com",
        "management.core.windows.net",
        "management.azure.com",
        "database.windows.net",
        "core.windows.net",
        "login.microsoftonline.com",
        "graph.windows.net",
        "graph.windows.net",
        # "trafficmanager.net", # Removing this as it cannot be found in the ARM function [Environment()]
        "vault.azure.net",
        "datalake.azure.net",
        "azuredatalakestore.net",
        "azuredatalakeanalytics.net",
        "vault.azure.net",
        "api.loganalytics.io",
        "api.loganalytics.iov1",
        "asazure.windows.net",
        "region.asazure.windows.net",
        "api.loganalytics.iov1",
        "api.loganalytics.io",
        "asazure.windows.net",
        "region.asazure.windows.net",
        "batch.core.windows.net"
    )
)

$HardcodedHostFinder = # Create a regex to find any reference
    [Regex]::new(($DisallowedHosts -join '|' -replace '\.', '\.'), 'IgnoreCase')

# Exception Regexs
$preceededBySchema = # The exception to the rule is a schema reference, 
    [Regex]::new('https://schema\.', 'IgnoreCase,RightToLeft') # so make a regex to look back for the rest of it.

    $IsDevOpsGalleryStorage = [Regex]::new('https://devopsgallerystorage\.blob\.', 'IgnoreCase,RightToLeft') # https://devopsgallerystorage.blob.core.windows.net/packages/azurerm.profile.2.8.0.nupkg

# Exception Regexs (end)

$parametersSection = Resolve-JSONContent -JSONPath "parameters" -JSONText $TemplateText


# Walk thru each host reference found 
foreach ($match in $HardcodedHostFinder.Matches($TemplateText)) { 
    
    # and see if it's preceeded by a schema, i.e. if there wasn't a schema before, or it wasn't directly before
    $schemaMatch = $preceededBySchema.Match($TemplateText, $match.Index)
    $notTheSchema = (-not $schemaMatch.Success -or $schemaMatch.Index + $schemaMatch.Length -ne $match.Index)
    
    # The Azure Automation library packages are in a devopsgallerystorage blob container
    $devOpsGalleryMatch = $IsDevOpsGalleryStorage.Match($templateText, $match.Index)
    $notTheDevOpsGallery = (-not $devOpsGalleryMatch.Success -or $devOpsGalleryMatch.Index + $devOpsGalleryMatch.Length -ne $match.Index)

    
    if ($parametersSection -and # If there was a parameters section, 
        (                       # and the url occured within it                  
            $match.Index -ge $parametersSection.Index -and 
            $match.Index -lt ( $parametersSection.Index  + $parametersSection.Length)
        )
    ) {
        continue                # this is not a problem.  Move onto the next match.
    }

    if ($notTheDevOpsGallery -and 
        $notTheSchema 
        ) { 
        Write-Error "Found hardcoded reference to $($match)" -ErrorId 'Hardcoded.Url.Reference' -TargetObject $match 
    }
}
