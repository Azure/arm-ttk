<#
.Synopsis
    Ensures that the VM Size is a Parameter
.Description
    Ensures that the Sizes of a virtual machine in a template are parameters
#>
param(
    [Parameter(Mandatory = $true)]
    [PSObject]
    $TemplateObject
)

$vmSizes = $TemplateObject.resources | Find-JsonContent -Key vmSize -Value * -Like

foreach ($vmSizeObject in $vmSizes) {
    
    $vmSize = $vmSizeObject.vmSize
    $resourceType = $vmSizeObject.ParentObject.type
    $resourceName = $vmSizeObject.ParentObject.name

    if ($vmSize -notmatch "\s{0,}\[.*?parameters\s{0,}\(\s{0,}'") {
        if ($vmSize -match "\s{0,}\[.*?variables\s{0,}\(\s{0,}'") {
            $resolvedVmSize = Expand-AzTemplate -Expression $vmSize -InputObject $TemplateObject
            if ($resolvedVmSize -notmatch "\s{0,}\[.*?parameters\s{0,}\(\s{0,}'") {
                Write-Error "VM Size for resourceType '$resourceType' named '$resourceName' must be a parameter" -TargetObject $vm
            }
        }
        else {
            Write-Error "VM Size for resourceType '$resourceType' named '$resourceName' must be a parameter" -TargetObject $vm
        }
    }

}
