<#
.Synopsis
    Matches an ARM variable
.Description
    Matches an Azure Resource Manager template variable.
#>
param(
# The name of the variable.  By default, matches any variable.
[string]
$Variable = '.+?'
)

$safeVariable = 
    # If there as a specific variable provided
    if ($PSBoundParameters['Variable']) {
        $Variable -replace # replace whitespace
            '\s','\s' -replace # then replace pound sign
            '#', '\#' -replace # then replace starting dollar sign
            '\$', '\$'
    } else {
        $Variable # otherwise, match any variable.
    }

@"
variables                       # the variables keyword
\s?                             # optional whitespace
\(                              # opening parenthesis
\s{0,}                          # more optional whitespace
'                               # a single quote
(?<VariableName>                # followed by the variable name
$safeVariable
)
'                               # a single quote
\s{0,}                          # more optional whitespace
\)                              # closing parenthesis
"@
