<#
.Synopsis
    Ensures that the VM Size is a Parameter
.Description
    Ensures that the Sizes of a virtual machine in a template are parameters
#>
param(
[Parameter(Mandatory=$true)]
[PSObject]
$TemplateObject
)

$MarketplaceWarning = $false

$vms = $TemplateObject.resources | Find-JsonContent -Key type -Value Microsoft.Compute/virtualMachines


foreach ($vm in $vms) {
    if ($vm.plan) {
        Write-Verbose "Skipping $($vm.Name) because it has a plan"
        continue
    }
    $hardwareProfile = $vm.properties.hardwareProfile

    if ($hardwareProfile -is [string]) { # If the hardwareProfile was a string,
        # set hardwareProfile to the resolved expression
        $hardwareProfile = Expand-AzTemplate -Expression $hardwareProfile -InputObject $TemplateObject
    }

    if (-not $hardwareProfile) { # If the hardwareProfile didn't resolve
        Write-TtkMessage -MarketplaceWarning $MarketplaceWarning "Could not resolve hardware profile" -TargetObject $vm # write an error
        continue # and move onto the next
    }


    $vmSize = $hardwareProfile.vmSize

    if ($vmSize -notmatch "\s{0,}\[.*?parameters\s{0,}\(\s{0,}'") {
        if ($vmSize -match "\s{0,}\[.*?variables\s{0,}\(\s{0,}'") {
            $resolvedVmSize = Expand-AzTemplate -Expression $vmSize -InputObject $TemplateObject
            if ($resolvedVmSize -notmatch "\s{0,}\[.*?parameters\s{0,}\(\s{0,}'") {
                Write-TtkMessage -MarketplaceWarning $MarketplaceWarning "VM Size must be a parameter" -TargetObject $vm
            }
        } else {
            Write-TtkMessage -MarketplaceWarning $MarketplaceWarning "VM Size must be a parameter" -TargetObject $vm
        }
    }
}
