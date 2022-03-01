﻿<#
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

    it 'Will expand innermost templates first' {
        $templatePath = $here | Join-Path -ChildPath NestedInnerTemplates.json
        $expanded = Expand-AzTemplate -TemplatePath $templatePath
        $expanded.innerTemplates.Count | Should -be 4
    }

    it 'Will expand templates containing bracket escape sequences' {
        $templatePath = $here | Join-Path -ChildPath InnerTemplateWithEscapeSequence.json
        $expanded = Expand-AzTemplate -TemplatePath $templatePath
        $expanded.innerTemplates.Count | Should -be 1
    }

    it 'Will report results from multiple inner templates' {
        $templatePath = $here | Join-Path -ChildPath MultipleInnerTemplates.json
        $expanded = Expand-AzTemplate -TemplatePath $templatePath
        $testOutput = Test-AzTemplate -TemplatePath $templatePath -Test "Parameters Must Be Referenced"
        $testOutput | 
            Select-Object -ExpandProperty Group -Unique | 
            Measure-Object | 
            Select-Object -ExpandProperty Count | 
            Should -BeGreaterThan 2
    }

    it 'Will complain (but not error) about a single blank file in an empty directory' {
        $templatePathRoot = $here | Join-Path -ChildPath "BlankFile$(Get-Random)"
        $null = New-Item -Path $templatePathRoot -ItemType Directory
        '' | Set-Content (Join-Path $templatePathRoot -ChildPath 'azureDeploy.json')
        $testHadErrorsOrExceptions = 
            try {
                $testOutput = Test-AzTemplate -TemplatePath $templatePathRoot *>&1
                $testOutput | Where-Object { $_ -is [Management.Automation.ErrorRecord] }
            } catch {
                $_
            }
        $testHadErrorsOrExceptions | Should -Be $null
        $templatePathRoot | Remove-Item
    }

    it 'Will not complain (and not error) given a blank template in a directory' {
        $templatePathRoot = $here | Join-Path -ChildPath "BlankFile$(Get-Random)"
        $null = New-Item -Path $templatePathRoot -ItemType Directory
        @'
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": { },
  "variables": { },
  "resources": [ ],
  "outputs": { }
}
'@ | Set-Content (Join-Path $templatePathRoot -ChildPath 'azureDeploy.json')
        $testHadErrorsOrExceptions = 
            try {
                $testOutput = Test-AzTemplate -TemplatePath $templatePathRoot *>&1
                $testOutput | Where-Object { $_ -is [Management.Automation.ErrorRecord] }
            } catch {
                $_
            }
        $testHadErrorsOrExceptions | Should -Be $null
        $templatePathRoot | Remove-Item
    }
}
