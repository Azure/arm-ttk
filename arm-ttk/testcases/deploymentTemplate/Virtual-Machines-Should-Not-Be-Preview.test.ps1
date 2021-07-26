<#
.Synopsis
    Ensures that all virtual machines are not using preview images
.Description
    Ensures that all virtual machine resources in a template are not using preview images.
#>
param(
    [Parameter(Mandatory = $true)]
    [PSObject]
    $TemplateObject
)

$storageProfiles = Find-JsonContent -Key storageProfile -InputObject $TemplateObject | 
Where-Object {
    $_.ParentObject.type -eq "Microsoft.Compute/virtualMachines" -or 
    $_.ParentObject.type -eq "Microsoft.Compute/virtualMachineScaleSets"
}

foreach ($sp in $storageProfiles) {
    $storageProfile = $sp.StorageProfile
    if ($storageProfile -is [string] -and $storageProfile -match '^\s{0,}\[') {
        $expanded = Expand-AzTemplate -Expression $storageProfile -InputObject $TemplateObject
        $storageProfile = $expanded
    }
    
    if ($storageProfile.imageReference -like '*preview' -or `
        $storageProfile.imageReference.version -like '*preview' -or `
        $storageProfile.imageReference.sku -like '*preview' -or `
        $storageProfile.imageReference.offer -like '*preview*') {
        Write-Error "StorageProfile for resource '$($sp.ParentObject.Name)' must not use a preview version" -TargetObject $sp -ErrorId VM.Using.Preview.Image
    }
}
