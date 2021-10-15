<#
.Synopsis
    SecureString/Object params used in outer scope eval nested deployments are available in the deployment obhect
.Description
    Resources of type Microsoft.Resources/deployments that use outer scope eval will evaluate expressions prior to being
    sent to the deployment engine.  This means that all properties are in the request in an evaluated state (clear text) and
    persisted on the deployment object
#>

param(
    # The Template Object
    [Parameter(Mandatory)]
    [PSObject]
    $TemplateObject
)

$deploymentResources = $TemplateObject.resources | 
Find-JsonContent -Key type -Value 'Microsoft.Resources/deployments'

foreach ($dr in $deploymentResources) {

    $scope = $dr.properties.expressionEvaluationOptions.scope
    $nestedTemplateText = @($dr.properties.template | ConvertTo-Json -Depth 100) -replace '\\u0027', "'"

    # If the template was scoped for inner evaluation, it will be extracted and converted into an empty template
    # If this the case, NestedTemplateText will be blank string or an empty JSON object, and we can continue on our way.
    if ((-not $nestedTemplateText) -or ($nestedTemplateText -replace '\s' -eq '{}')) { 
        continue
    }

    # if scope is not present or set to outer, flag it if it has secureParams
    if (!$scope -or $scope -eq 'outer') {

        # find all secureString and secureObject parameters
        foreach ($parameterProp in $templateObject.parameters.psobject.properties) {
            $parameter = $parameterProp.Value
            $name = $parameterProp.Name
            # If the parameter is a secureString or secureObject it shouldn't be in the outputs:
            if ($parameter.Type -eq 'securestring' -or $parameter.Type -eq 'secureobject') { 

                # Create a Regex to find the parameter
                $findParam = [Regex]::new(@"
parameters           # the parameters keyword
\s{0,}               # optional whitespace
\(                   # opening parenthesis
\s{0,}               # more optional whitespace
'                    # a single quote
$name                # the parameter name
'                    # a single quote
\s{0,}               # more optional whitespace
\)                   # closing parenthesis
"@,
                    # The Regex needs to be case-insensitive
                    'Multiline,IgnoreCase,IgnorePatternWhitespace'
                )

                $exprStrOrQuote = [Regex]::new('(?<!\\)[\[\"]', 'RightToLeft')

                $matched = $($findParam.Match($nestedTemplateText))
                if ($matched.Success) {
                    $matchIndex = $findParam.Match($nestedTemplateText).Index
                    $preceededBy = $exprStrOrQuote.Match($nestedTemplateText, $matchIndex).Value
                    if ($preceededBy -eq '[') {
                        Write-Error -Message "Microsoft.Resources/deployments/$($dr.name) is an outer scope nested deployment that contains a $($parameterProp.Value.Type) type parameter: `"$name`"" -ErrorId NestedDeployment.Contains.SecureParameter -TargetObject $parameterProp
                    }
                }
            }
        }

        # find all list*() functions


        $findListFunc = [Regex]::new(@"
(?>    # we don't want to flag a UDF that might be called "myListOfIps" so we need to check the char preceeding list*()
\[|    # bracket
\(|    # paren
,      # comma
)      # and the (?>  ) syntax says this is not included in the match because we need to check for expressions explicitly below
\s{0,}
list\w{0,}
\s{0,}
\(
"@, 'Multiline,IgnoreCase,IgnorePatternWhitespace')
        
        $exprStrOrQuote = [Regex]::new('(?<!\\)[\[\"]', 'RightToLeft')
        
        $matched = $($findListFunc.Match($nestedTemplateText))
        if($matched.Success) {
            $matchIndex = $findListFunc.Match($nestedTemplateText).Index
            $preceededBy = $exprStrOrQuote.Match($nestedTemplateText, $matchIndex).Value
            if ($preceededBy -eq '[') {
                Write-Error -Message "Microsoft.Resources/deployments/$($dr.name) is an outer scope nested deployment that contains a list*() function: $($matched.Value)" -ErrorId NestedDeployment.Contains.ListFunction -TargetObject $dr
            }
        }
    }
}