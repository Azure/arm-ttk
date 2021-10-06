<#
.Synopsis
    TODO: summary of test
.Description
    TODO: describe this test
#>

param(
[Parameter(Mandatory=$true,Position=0)]
[PSObject]
$TemplateObject
)

$RULE_ID_START = "BP-14-"

# Walk thru each of the parameters in the template object
foreach ($parameterInfo in $templateObject.parameters.psobject.properties) {
    $parameterName = $parameterInfo.Name
    $parameter = $parameterInfo.Value
    $Min = $null
    $Max = $null
    if ($parameter.psobject.properties.item('maxValue')) {
        if ($parameter.maxValue -isnot [long] -and $parameter.maxValue -isnot [int]) {  # PS Core is interpreting the int/longs as long
            Write-Error "$($ParameterName) maxValue is not an [int] or [long] (it's a [$($parameter.maxValue.GetType())])" `
                -ErrorId Parameter.Max.Not.Int -TargetObject (Set-RuleID -RuleIDStart $RULE_ID_START -CurrentRuleNumber 1 -TargetObject $parameter)
            continue
        } else {
            $max = $parameter.maxValue
        }

    }
    if ($parameter.psobject.properties.item('minValue')) {
        if ($parameter.minValue -isnot [long] -and $parameter.minValue -isnot [int]) {
            Write-Error "$($ParameterName) minValue is not an [int] or [long] (it's a [$($parameter.minValue.GetType())])" `
                -ErrorId Parameter.Min.Not.Int -TargetObject (Set-RuleID -RuleIDStart $RULE_ID_START -CurrentRuleNumber 2 -TargetObject $parameter)           
            continue
        } else {
            $min = $Parameter.minValue
        }
    }

    if ($max -eq $null -and $min -ne $null){
        Write-Error "$ParameterName missing max value" -ErrorId Parameter.Missing.Max -TargetObject (Set-RuleID -RuleIDStart $RULE_ID_START -CurrentRuleNumber 3 -TargetObject $parameter)           
    }

    if ($max -ne $null -and $min -eq $null){
        Write-Error "$ParameterName missing min value" -ErrorId Parameter.Missing.Min -TargetObject (Set-RuleID -RuleIDStart $RULE_ID_START -CurrentRuleNumber 4 -TargetObject $parameter)       
    }
}