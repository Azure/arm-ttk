<#
.Synopsis
    Ensures that the VM Size is a Parameter
.Description
    Ensures that the Sizes of a virtual machine in a template are parameters
#>
param(
    # The template object, with inline templates removed to keep the proper scope of tests when parsing - could be the mainTemplate.json or a nested template.
    [Parameter(Mandatory = $true)]
    [PSObject]
    $TemplateObject,

    # The original mainTemplate.json object, without any modifications - nested templates are still inline ($TemplateObject has replaced any inner templates with blanks).
    [PSObject]
    $OriginalTemplateObject,

    # The list of inner templates
    [PSObject[]]
    $InnerTemplates,

    # If set, the current -TemplateObject is an inner template.
    [switch]
    $IsInnerTemplate
)

if ($IsInnerTemplate) { return }   # If we are evaluating an inner template, return (this test should run once per file)
if (-not $OriginalTemplateObject) { return} # If there was no original template object, then there is nothing to check.

# Get all VMSizes used throughout the template and any inner templates
$vmSizes = Find-JsonContent -Key vmSize -Value * -Like -inputObject $OriginalTemplateObject
$vmSizeTopLevelParameterDeclared = $false
foreach ($vmSizeObject in $vmSizes) {
    
    $vmSize = $vmSizeObject.vmSize
    # If the vmSize was in a parameter, we will want to continue
    if ($vmSizeObject.JSONPath -match '^parameters' -or 
        $vmSizeObject.JSONPath -match '\.parameters\.') {
        # but not before we check if it was an inner template
        if ($vmSizeObject.ParentObject[0].expressionEvaluationOptions.scope -eq 'inner') {
            # If it was an inner template, check to make sure that the inner template contains a vmSize
            if (-not ($vmSize.Value | ?<ARM_Parameter>)) {
                Write-Error "Nested template parameter vmSize does not map to a parameter" -TargetObject $vmSizeObject
                continue
            }             
        } else {

            # Otherwise, make note of the fact that we have a parameter called VMSize
            $vmSizeTopLevelParameterDeclared = $true
        }
        
        # If the VMSize was in the properties passed to a template, it is not declaring the parameter.
        # Therefore, if we determine that we are examining properties, we should validate this as any other VMSize parameter.
        if ($vmSizeObject.JSONPath -notmatch 'resources\[\d+\]\.properties\.parameters') {           
            continue
        }
    }

    # The only other places we should find VMSizes are in resources.

    # Keep track of the type and name.
    $resourceType = $vmSizeObject.ParentObject.type
    $resourceName = $vmSizeObject.ParentObject.name
    
    
    if (-not ($vmSize | ?<ARM_Parameter>)) { # If the VMSize does not have a parameter reference
        if ($vmSize | ?<ARM_Variable>) {   # but does have a variable reference
            # try expanding the variable
            $resolvedVmSize = Expand-AzTemplate -Expression $vmSize -InputObject $OriginalTemplateObject
            # if the expanded variable does not contain a parameter
            if ($resolvedVmSize -notmatch "\s{0,}\[.*?parameters\s{0,}\(\s{0,}'") {
                # write an error.
                Write-Error "VM Size for resourceType '$resourceType' named '$resourceName' must be a parameter" -TargetObject $vm
            }
        }
        else {
            # If the vmSize had no variable or parameter references, write an error.
            Write-Error "VM Size for resourceType '$resourceType' named '$resourceName' must be a parameter" -TargetObject $vm
        }
    }
}