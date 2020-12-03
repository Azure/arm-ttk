Writing TTK Tests
=======

Let's write a simple test.

We're going to write a test to make sure each parameter in our template is referenced.

### Test Location

This test should defined in ./testcases/deploymentTemplate/Parameters-Must-Be-Referenced.ps1.

Tests in /testcases/deploymentTemplate will run against any JSON object with a $schema like \*deploymentTemplate\*.


### Test Structure

At the top, there's some inline help.  This is useful for anyone who wants to know more about your validation.
You can run Get-Help ./testcases/deploymentTemplate/Parameters-Must-Be-Referenced.ps1.

~~~PowerShell
<#
.Synopsis
    Ensures that parameters are referenced
.Description
    Ensures that all Azure Resource Manager Template
#>
~~~

Next we have the test parameters.  These are used to bind to information from the Azure Resource Manager Template.

The TemplateObject parameter will pass the template as an object, converted from JSON.
The TemplateText parameter will pass the raw text of the template.

You only need to pass the information needed for your test.

~~~PowerShell
param(
    # The Template Object
    [Parameter(Mandatory = $true, Position = 0)]
    [PSObject]
    $TemplateObject,

    # The Template JSON Text
    [Parameter(Mandatory = $true, Position = 0)]
    [PSObject]
    $TemplateText
)
~~~

### Test Logic

We want to loop over each parameter.

Each parameter will have be defined as a property on the .Parameters object within a template.

We can use PowerShell to loop over the parameter object properties.

~~~PowerShell

foreach ($parameter in $TemplateObject.parameters.psobject.properties) {
    # If the parameter name starts with two underscores,
    if ($parameter.Name -like '__*') { continue } # skip it, this is a pattern we use to allow for ignoring a parameter being used
    
    # See if we found the parameter.  This uses the pattern generator defined in/Regex/ARM/Parameter.regex.ps1

    $foundRefs = @($TemplateText | & ${?<ARM_Parameter>} -Parameter $parameter.Name) 
    if (-not $foundRefs) { # If we didn't, error
        Write-Error -Message "Unreferenced parameter: $($Parameter.Name)" -ErrorId Parameters.Must.Be.Referenced -TargetObject $parameter
    } else {
        # We need to ensure that a given reference is in an expression.  
        # To do that, we use another pattern, ?<ARM_BracketOrQuote>, defined in /Regex/ARM/BracketOrQuote.ps1
        foreach ($fr in $foundRefs) { # Walk thru each reference
            # In this case, we want to look backwards, starting just after our match.  
            # So we pass -RightToLeft and -Start.
            $foundQuote = $templateText | & ${?<ARM_BracketOrQuote>} -RightToLeft -Start ($fr.Index + 1)
            # At this point, $foundQuote could contain either a double quote or a bracket
            # It it was a double quote, the parameter reference is not in an expression.
            if ($foundQuote.Value -eq '"') { 
                # so we produce an error.
                Write-Error -Message "Parameter reference is not contained within an expression: $($Parameter.Name)" -ErrorId Parameters.Must.Be.Referenced.In.Expression -TargetObject $parameter
            }
        }
    }
}
~~~

---

To see how to write unit tests for your TTK tests, see [Writing TTK Unit Tests](Writing_TTK_Unit_Tests.md)
