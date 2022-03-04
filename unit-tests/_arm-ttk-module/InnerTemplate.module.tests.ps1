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
        $testOutput = $here | 
            Split-Path | 
            Join-Path -ChildPath DeploymentTemplate-Must-Not-Contain-Hardcoded-Uri | 
            Join-Path -ChildPath Fail | 
            Join-Path -ChildPath Hardcoded-Uri-In-InnerTemplate.json |
            Get-ChildItem |
            Test-AzTemplate -Test DeploymentTemplate-Must-Not-Contain-Hardcoded-Uri
        $testOutput |
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
    
    it 'Will expand inner templates and their grandchildren correctly' {
        $templatePath = $here | Join-Path -ChildPath MultipleInnerTemplatesWithUnreferencedParameters.json
        $testOutput   = Test-AzTemplate -TemplatePath $templatePath -Test "Parameters Must Be Referenced"
        # There should be 5 outputs
        $testOutput.Count | Should -be 5
        # The first should come from root
        $testOutput[0].AllOutput[0].TargetObject.JSONPath | Should -Be parameters.NotUsedAtRoot
        
        # The next template should be "NotUserInInnerTemplate1" (the first inner template)
        $testOutput[1].AllOutput[0].TargetObject.JSONPath | Should -Be parameters.NotUsedInInnerTemplate1

        # The location of the inner template errors should be adjusted, thus the .Line should be greater
        $testOutput[1].AllOutput[0].Location.Line | Should -BeGreaterThan $testOutput[0].AllOutput[0].Location.Line

        # The next template should be "NotUsedInInnerInnerTemplate1" (the first grandchild)
        $testOutput[2].AllOutput[0].TargetObject.JSONPath | Should -Be parameters.NotUsedInInnerInnerTemplate1
        $testOutput[2].AllOutput[0].Location.Line | Should -BeGreaterThan $testOutput[1].AllOutput[0].Location.Line
    
        
        # The next template should be "NotUsedInInnerTemplate2" (the second template)
        $testOutput[3].AllOutput[0].TargetObject.JSONPath | Should -Be parameters.NotUsedInInnerTemplate2
        $testOutput[3].AllOutput[0].Location.Line | Should -BeGreaterThan $testOutput[2].AllOutput[0].Location.Line

        # The next template should be "NotUsedInInnerInnerTemplate2" (the second grandchild)
        $testOutput[4].AllOutput[0].TargetObject.JSONPath | Should -Be parameters.NotUsedInInnerInnerTemplate2
        $testOutput[4].AllOutput[0].Location.Line | Should -BeGreaterThan $testOutput[3].AllOutput[0].Location.Line
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
        $templatePathRoot | Remove-Item -Recurse -Force
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
        $templatePathRoot | Remove-Item -Recurse -Force
    }
}
