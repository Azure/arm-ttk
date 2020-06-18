<#
.Synopsis
    Ensures that all virtual machines are not using preview images
.Description
    Ensures that all virtual machine resources in a template are not using preview images.
#>
param(
[Parameter(Mandatory=$true)]
[PSObject]
$TemplateObject
)

$storageProfiles = Find-JsonContent -Key storageProfile -InputObject $TemplateObject

foreach ($sp in $storageProfiles) {
    $storageProfile = $sp.StorageProfile
    if (-not $storageProfile.imageReference) {
        Write-Output "Virtual machine resource '$($sp.ParentObject.Name)' has no image to reference" -TargetObject $sp # VMSS scale up does not have a imageRef by design
    }

    if ($storageProfile.imageReference -like '*-preview' -or $storageProfile.imageReference.version -like '*-preview') {
        Write-Error "Virtual machine resource '$($sp.ParentObject.Name)' must not use a preview image" -TargetObject $sp -ErrorId VM.Using.Preview.Image
    }
}
