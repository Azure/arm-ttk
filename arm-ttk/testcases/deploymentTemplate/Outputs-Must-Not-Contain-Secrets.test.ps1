<#
.Synopsis
    Ensures outputs do not contain secrets.
.Description
    Ensures outputs do not contain expressions that would expose secrets, list*() functions or secure parameters.
.Example
    Test-AzTemplate -TemplatePath .\100-marketplace-sample\ -Test Outputs-Must-Not-Contain-Secrets
.Example
    .\IDs-Should-Be-Derived-From-ResourceIDs.test.ps1 -TemplateObject (Get-Content ..\..\..\unit-tests\IOutputs-Must-Not-Contain-Secrets.test.json -Raw | ConvertFrom-Json)
#>
param(
[Parameter(Mandatory=$true,Position=0)]
[PSObject]
$TemplateObject
)

<#
This test should flag using runtime functions that list secrets or secure parameters in the outputs

    "sample-output": {
      "type": "string",
      "value": "[listKeys(parameters('storageAccountName'),'2017-10-01').keys[0].value]"
    }
    "sample-output-secure-param": {
      "type": "string",
      "value": "[concat('connectstring stuff', parameters('adminPassword'))]"
    }

#>

    $isListFunc = [Regex]::new(@'
(?>        # we don't want to flag a UDF that might be called "myListOfIps" so we need to check the char preceeding list*()
    \[|    # bracket
    \(|    # paren
    ,      # comma
)          # and the (?>  ) syntax says this is not included in the match because we need to check for expressions explicitly below
\s{0,}
list\w{0,}
\s{0,}
\(
'@, 'Multiline,IgnoreCase,IgnorePatternWhitespace')

$exprStrOrQuote = [Regex]::new('(?<!\\)[\[\"]', 'RightToLeft')

#look at each output value property
foreach ($output in $TemplateObject.outputs.psobject.properties) {

    $outputText = $output.value | ConvertTo-Json # search the entire output object to cover output copy scenarios
    if ($isListFunc.IsMatch($outputText)) {
        
        foreach ($m in $isListFunc.Matches($outputText)) {
            # Go back and find if it starts with a [ or a "
            $preceededBy = $exprStrOrQuote.Match($outputText, $m.Index + 1) # add 1 to index since the match has to include "list" plus at least one other char
            if ($preceededBy.Value -eq '[') {  # If it starts with a [, it's a real ref
                Write-Error -Message "Output contains secret: $($output.Name)" -ErrorId Output.Contains.Secret -TargetObject $output   
            }
        }
    }
    if ($output.Name -like "*password*"){
        Write-Error -Message "Output name suggests secret: $($output.Name)" -ErrorId Output.Contains.Secret.Name -TargetObject $output
    }
}

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
        
        foreach ($output in $TemplateObject.outputs.psobject.properties) {

            $outputText = $output.Value | ConvertTo-Json -Depth 100
            $outputText = $outputText -replace # and replace 
                '\\u0027', "'" # unicode-single quotes with single quotes (in case we are not on core).

            $matched = $($findParam.Match($outputText))
            if ($matched.Success) {
                
                $matchIndex = $findParam.Match($outputText).Index
                $preceededBy = $exprStrOrQuote.Match($outputText, $matchIndex).Value
                if ($preceededBy -eq '[') {
                    Write-Error -Message "Output contains $($parameterProp.Value.Type) parameter: $($output.Name)" -ErrorId Output.Contains.SecureParameter -TargetObject $output
                }
            }
        }        
    }
}

