<#
.Synopsis
    arm-ttk InnerTemplate Pester tests
.Description
    Pesters tests for the InnerTemplate functionality in Azure Resource Manager Template Toolkit (arm-ttk).

    These tests make sure arm-ttk is working with InnerTemplates properly, and are not to be confused with the validation within arm-ttk.
   
#>
$here = Split-Path -Parent $MyInvocation.MyCommand.Path


Push-Location -Path "$here\..\..\arm-ttk"

describe InnerTemplates {
    it 'Will only generate a failure from an InnerTemplate' {
        $here | 
            Split-Path | 
            Join-Path -ChildPath DeploymentTemplate-Must-Not-Contain-Hardcoded-Uri | 
            Join-Path -ChildPath Fail | 
            Join-Path -ChildPath Hardcoded-Uri-In-InnerTemplate.json |
            Get-ChildItem |
            Test-AzTemplate -Test DeploymentTemplate-Must-Not-Contain-Hardcoded-Uri |
            Measure-Object |
            Select-Object -ExpandProperty Count |
            Should -Be 1
    }
}
