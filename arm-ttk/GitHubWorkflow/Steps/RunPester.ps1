<#
.Synopsis
    Runs Pester
.Description
    Runs Pester tests after importing a PowerShell module
#>
param(
# The module path.  If not provided, will default to the second half of the repository ID.
[string]
$ModulePath,
# The Pester max version.  By default, this is pinned to 4.99.99.
[string]
$PesterMaxVersion = '4.99.99'
)

$global:ErrorActionPreference = 'continue'
$global:ProgressPreference    = 'silentlycontinue'

$orgName, $moduleName = $env:GITHUB_REPOSITORY -split "/"
if (-not $ModulePath) { $ModulePath = ".\$moduleName.psd1" }
$importedPester = Import-Module Pester -Force -PassThru -MaximumVersion $PesterMaxVersion
$importedModule = Import-Module $ModulePath -Force -PassThru
$importedPester, $importedModule | Out-Host



$result = 
    Invoke-Pester -PassThru -Verbose -OutputFile ".\$moduleName.TestResults.xml" -OutputFormat NUnitXml `
        -CodeCoverage "$($importedModule | Split-Path)\*-*.ps1" -CodeCoverageOutputFile ".\$moduleName.Coverage.xml"

"::set-output name=TotalCount::$($result.TotalCount)",
"::set-output name=PassedCount::$($result.PassedCount)",
"::set-output name=FailedCount::$($result.FailedCount)" | Out-Host
if ($result.FailedCount -gt 0) {
    "::debug:: $($result.FailedCount) tests failed"
    foreach ($r in $result.TestResult) {
        if (-not $r.Passed) {
            "::error::$($r.describe, $r.context, $r.name -join ' ') $($r.FailureMessage)"
        }
    }
    throw "::error:: $($result.FailedCount) tests failed"
}
