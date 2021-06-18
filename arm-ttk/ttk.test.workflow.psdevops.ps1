#requires -Module PSDevOps
Import-BuildStep -ModuleName arm-ttk
Push-Location $PSScriptRoot
New-GitHubWorkflow -Name RunPester -On Demand, Push, PullRequest -Job TestPowerShellOnLinux  -Environment @{
    ModulePath = '.\arm-ttk\arm-ttk.psd1'
} -RootDirectory ($pwd | Split-Path) |
    Set-Content -Path ../.github/workflows/run-unit-tests.yml -PassThru -Encoding UTF8
Pop-Location
