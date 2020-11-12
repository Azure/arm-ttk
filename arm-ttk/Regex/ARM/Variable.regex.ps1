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

@"
variables                       # the variables keyword
\s?                             # optional whitespace
\(                              # opening parenthesis
\s{0,}                          # more optional whitespace
'                               # a single quote
(?<VariableName>                # followed by the variable name
$($Variable -replace '\s','\s')    
)
'                               # a single quote
\s{0,}                          # more optional whitespace
\)                              # closing parenthesis
"@


