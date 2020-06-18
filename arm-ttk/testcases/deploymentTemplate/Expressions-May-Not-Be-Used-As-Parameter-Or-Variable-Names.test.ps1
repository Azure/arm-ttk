<#
.Synopsis
    Ensures Expressions may not be used to name parameters/variables
.Description
    Ensures that Expressions may not be used in the name of a parameter or variable.
#>
param(
[Parameter(Mandatory)]
[PSObject]
$TemplateObject
)


$expressionStart = '^\s{0,}\['
$expressionEnd = '\]\s{0,}$'

$variableNames = $TemplateObject.variables.psobject.properties | Select-Object -ExpandProperty Name
foreach ($vn in $variableNames) {
    if ($vn -match $expressionStart -and $vn -match $expressionEnd) {
        Write-Error "Variable name is an expression: $vn" -TargetObject $vn -ErrorId 'Variable.Name.Is.Expression' 
    }
}
 
$parameterNames = $TemplateObject.parameters.psobject.properties | Select-Object -ExpandProperty Name
foreach ($pn in $parameterNames) {
    if ($pn -match $expressionStart -and $pn -match $expressionEnd) {
        Write-Error "Parameter name is an expression: $pn" -TargetObject $pn -ErrorId 'Parameter.Name.Is.Expression' 
    }
}
