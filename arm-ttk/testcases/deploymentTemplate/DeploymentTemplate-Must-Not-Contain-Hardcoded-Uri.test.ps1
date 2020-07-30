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
        "trafficmanager.net",
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

$preceededBySchema = # The exception to the rule is a schema reference, 
    [Regex]::new('https://schema\.', 'IgnoreCase,RightToLeft') # so make a regex to look back for the rest of it.

# Walk thru each host reference found 
foreach ($match in $HardcodedHostFinder.Matches($TemplateText)) { 
    # and see if it's preceeded by a schema.
    $schemaMatch = $preceededBySchema.Match($TemplateText, $match.Index)
    if (-not $schemaMatch.Success -or # If the wasn't a schema before, or it wasn't directly before
        ($schemaMatch.Index + $schemaMatch.Length -ne $match.Index)) { # error.
        Write-Error "Found hardcoded reference to $($match)" -ErrorId 'Hardcoded.Url.Reference' -TargetObject $match 
    }
}
