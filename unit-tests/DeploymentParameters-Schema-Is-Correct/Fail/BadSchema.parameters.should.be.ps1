﻿param(
[PSObject[]]
$Results
)


$unexpectedErrors = $Results | 
    ForEach-Object { $_.Errors } |
    Select-Object -ExpandProperty Exception | 
    Where-Object {
        $_.Message -notlike '*DeploymentParameters has an unexpected Schema.*'
    } |
    Select-Object -ExpandProperty Message

if ($unexpectedErrors) {
    throw $unexpectedErrors
}