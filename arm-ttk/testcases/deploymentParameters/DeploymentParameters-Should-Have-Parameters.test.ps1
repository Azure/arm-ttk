<#
.Synopsis
    Ensures that parameters file has parameters
.Description
    Ensures that parameters file has parameters
    If a parameters file has no '.parameters' property or any other properties then it has no parameters. 
#>
param(
    # The parameter object
    [Parameter(Mandatory=$true,Position=0)]
    [PSObject]
    $ParameterObject
)

if (-not $ParameterObject.'$schema' -and -not $ParameterObject.contentVersion) {
    return
}

if (-not $ParameterObject.parameters) {
    Write-Error -ErrorId Parameters.Missing.Parameters -Message "No parameters exists" 
} 