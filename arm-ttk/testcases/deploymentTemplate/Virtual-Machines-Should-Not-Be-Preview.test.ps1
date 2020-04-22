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

#? Should this be using Find-JsonContent?

foreach ($resource in $templateObject.resources) {
    # This is a PowerShell trick to simplify multiple -ors
    # -notcontains checks that a list (on the left side) doesn't contain a value (on the right side)
    # So this test will ignore resources that aren't /virtualmachines or /virtualmachineassets
    if ('microsoft.compute/virtualmachinescalesets', 
        'microsoft.compute/virtualmachines' -notcontains $resource.type) {
        continue
    }
    # Check for the VMSS property and if it's not there, check the VM property
    $imageReference = $resource.virtualmachineprofile.storageProfile.imageReference
    if (-not $imageReference) { 
        # If we couldn't find the reference on the .virtualmachineprofile, just look for a .storageprofile
        $imageReference = $resource.properties.storageProfile.imageReference
    }
    if (-not $imageReference) {
        Write-Error "Virtual machine resource $($resource.Name) has no image to reference" -TargetObject $resource -ErrorId VM.Missing.Image
    }

    if ($imageReference -like '*-preview' -or $imageReference.version -like '*-preview') {
        Write-Error "Virtual machine resource $($resource.Name) must not use a preview image" -TargetObject $ResourceType -ErrorId VM.Using.Preview.Image
    }
}
