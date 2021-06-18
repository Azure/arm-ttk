#requires -Module PSDevOps
Import-BuildStep -ModuleName arm-ttk
Push-Location $PSScriptRoot
New-GitHubWorkflow -On Push -Job RunTTK | Set-Content .\SampleWorkflow.yml -Encoding UTF8
Pop-Location
