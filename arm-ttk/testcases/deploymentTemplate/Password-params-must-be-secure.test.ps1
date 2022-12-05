<#
.Synopsis
    Ensures parameters that look like passwords are secure.
.Description
    Ensures parameters that have *password* in the name are of some secure type.
.Example
    Test-AzTemplate -TemplatePath .\100-marketplace-sample\ -Test Password-params-must-be-secure
.Example
    .\Password-params-must-be-secure.test.ps1 -TemplateObject (Get-Content ..\..\..\unit-tests\Password-params-must-be-secure.test.json -Raw | ConvertFrom-Json)
#>
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [PSObject]
    $TemplateObject
)

<#
This test should flag any parameters that look like they might be used as passwords and are not using a secure* type declaration

    "adminUsername": {
      "type": "string" // this is fine
    }
    "adminPassword": {
      "type": "string" // this is not
    }

#>

# find all parameters
foreach ($parameter in $templateObject.parameters.psobject.properties) {
    
    $type = $parameter.value.type
    $name = $parameter.name
    
    # using a name matching pattern to decide if this should be secured or not
    if ($name -like "*password*" -or 
        $name -like "*secret*" -or
        $name -like "*accountkey*") {
        # if it's not secure, flag it

        if ($type -ne 'securestring' -and $type -ne 'secureobject' -and $type -ne 'bool') {
            #except certain patterns we know about in ARM
            # secret + Permissions (keyVault secret perms is an accessPolicy property)
            # secret + Version (url or simply the version property of a secret)
            # secret + url
            # secret + name
            if ($name -like "*secret*" -and
                   ($name -like "*permission*" -or
                    $name -like "*version*" -or
                    $name -like "*url*" -or
                    $name -like "*uri*" -or 
                    $name -like "*name*")
                )
            {
                Write-Warning "Skipping parameter `"$name`""
            }
            else {
                Write-Error -Message "Parameter `"$name`" is of type `"$type`" but should be secure." -ErrorId Password.Param.Not.Secure -TargetObject $parameter
            }      
        }
    }
}

