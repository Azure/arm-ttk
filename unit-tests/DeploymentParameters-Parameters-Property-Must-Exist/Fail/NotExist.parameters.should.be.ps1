param(
[PSObject[]]
$Results
)


$unexpectedErrors = $Results | 
    ForEach-Object { $_.Errors } |
    Select-Object -ExpandProperty Exception | 
    Where-Object {
        $_.Message -notlike '*Parameters property must exist in the parameters file*'
    } |
    Select-Object -ExpandProperty Message

if ($unexpectedErrors) {
    throw $unexpectedErrors
}