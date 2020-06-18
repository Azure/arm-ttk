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

# The cached date of all environments (contained in /cache/AllEnvironments.cache.json)
[PSObject[]]
$AllEnvironments
)

$uniqueHosts = # Walk thru all environments
    @(foreach ($envData in $AllEnvironments) {
        foreach ($prop in $envData.PSObject.properties){ # and each property
            $uriValue = $prop.Value -as [uri] # that is a URI
            if ($uriValue.DnsSafeHost) { # with a host.
                $uriValue.DnsSafeHost # Pick out that host.
            }
        }
    }) | Select-Object -Unique # and return each unique item



$HardcodedHostFinder = # Create a regex to find any reference
    [Regex]::new(($uniqueHosts -join '|' -replace '\.', '\.'), 'IgnoreCase')

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
