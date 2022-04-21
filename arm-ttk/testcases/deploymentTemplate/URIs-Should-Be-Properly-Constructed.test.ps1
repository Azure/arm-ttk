<#
.Synopsis
    Ensures that URIs are properly constructed
.Description
    Ensures that properties named URI or URL are properly constructed, and do not use and -FunctionNotAllowedInUri
#>
param(
    # The template object
    [Parameter(Mandatory = $true, Position = 0)]
    [PSObject]
    $TemplateObject,

    # A list of functions not allowed in the uri.  By default, format and concat.
    [string[]]
    $FunctionNotAllowedInUri = @('format', 'concat')
)

# commenting out the test due to # 417
$foundObjects = Find-JsonContent -InputObject $TemplateObject -Key 'ur[il]$' -Match 

foreach ($found in $foundObjects) { # Walk over each found object
    foreach ($prop in $found.psobject.properties) { # then walk thru each property
        if ($prop.Name -notmatch 'ur[il]$') { continue } # skipping ones that are not uri/url
        if (-not $prop.value | ?<ARM_Template_Expression>) { continue } # and ones that do not contain an expression.

        # If the value contained expressions, but not the function uri
        $foundBadFunction = $prop.Value | ?<ARM_Template_Function> -FunctionName ($FunctionNotAllowedInUri -join '|')
        $foundUriFunction = $prop.Value | ?<ARM_Template_Function> -FunctionName uri

        if (
            ($foundBadFunction -and -not $foundUriFunction) -or 
            ($foundBadFunction.Index -lt $foundUriFunction.Index -and $foundBadFunction)
        ) {
            Write-Error "Function '$($foundBadFunction.Groups['FunctionName'].Value)' found within '$($prop.Name)'" -TargetObject $found -ErrorId "URI.Improperly.Constructed"
        }
    }
}
