<#
.Synopsis
    Ensures that all commandsToExecute guard secrets
.Description
    Ensures that all commandsToExecute are within protectedSettings if the command contains a secure parameter or list function.
#>
param(
[Parameter(Mandatory=$true)]
[PSObject]
$TemplateObject
)


# Find all references to an commandToExecute
$commandsToExecute = $TemplateObject | 
    Find-JsonContent -Key commandToExecute  -Value * -Like |
    Where-Object { -not $_.ParentObject[0].'$schema' } # unless they're on a top-level property.


foreach ($command in $commandsToExecute) {
    if ($command.parentObject.protectedSettings.commandToExecute) { # If the command is already within protected settings, ok
        continue
    }
    $commandUsesAListFunction = "$($command.commandToExecute)" | ?<ARM_List_Function>

    if ($commandUsesAListFunction) {
        Write-Error "CommandToExecute uses '$commandUsesAListFunction', but is not in .protectedSettings" -ErrorId CommandToExecute.Unprotected.List -TargetObject $command
        continue
    }

    $commandToExecuteReferencedParameters = 
        $command.commandToExecute | 
            ?<ARM_Parameter> -Extract | 
                Select-Object -ExpandProperty ParameterName

    foreach ($ref in $commandToExecuteReferencedParameters) {
        $refType = $TemplateObject.Parameters.$ref.type
        if ($refType -in 'SecureString', 'SecureObject') {            
            Write-Error "CommandToExecute references parameter '$ref' of type '$refType', but is not in .protectedSettings" -ErrorId CommandToExecute.Unprotected.Parameter -TargetObject $command
            continue
        }
    }
}


