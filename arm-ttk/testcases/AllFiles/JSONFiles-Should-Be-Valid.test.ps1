<#
.Synopsis
    Ensures that all JSON files are valid
.Description
    Ensures that all JSON files are valid syntax and can be imported.
#>
param(
[PSObject[]]
$FolderFiles
)

foreach ($file in $FolderFiles) {
    if ($file.FullPath -notmatch '\.json(c)?$') { continue }
    $imported = Import-Json -FilePath $TemplateFullPath -ErrorAction SilentlyContinue -ErrorVariable ConvertIssue
    if (-not $imported) {
        Write-Error "Could not import '$TemplateFullPath'" -TargetObject $TemplateFullPath -ErrorId "Invalid.JSON"
    }
}
