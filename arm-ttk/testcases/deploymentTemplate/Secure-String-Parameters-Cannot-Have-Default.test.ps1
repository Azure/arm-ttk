<#
.Synopsis
    Ensures SecureString Parameters do not have a default
.Description
    Ensures Parameters of the type 'SecureString' do not have a default value, or have a default using a [newguid()]
#>
param(
    # The template object
    [Parameter(Mandatory = $true, Position = 0)]
    [PSObject]
    $TemplateObject
)

$usedNewGuid = [Regex]::new(@'
\[             # Starting bracket
\s{0,}         # ... optional whitespace
newGuid        # the literal 'newGuid'
\s{0,}         # ... optional whitepace
\(             # open parenthesis
\s{0,}         # optional whitespace
\)             # close parenthesis
\s{0,}         # optional whitespace
\]             # Closing bracket
'@, 'Multiline,IgnoreCase,IgnorePatternWhitespace')

# Walk thru each parameter in the template object
foreach ($parameterProp in $templateObject.parameters.psobject.properties) {
    $parameter = $parameterProp.Value
    $name = $parameterProp.Name

    # If the parameter is a secureString type and has a defaultValue:
    if ($parameter.Type -eq 'securestring' -and $parameter.defaultValue) {
        # the defaultValue must be an empty string "" or must be an expression that contains use the newGuid() function
        if ($parameter.defaultValue -and
            -not ($parameter.defaultValue | ?<ARM_Template_Function> -FunctionName 'newguid')) {
            # Will return true when defaultvalue is not null or blank (blank values are OK).
            Write-Error -Message "Parameter $name is a SecureString and must not have a default value unless it is an expression that contains the newGuid() function." `
                -ErrorId SecureString.Must.Not.Have.Default -TargetObject $parameter
        }
    }
}
