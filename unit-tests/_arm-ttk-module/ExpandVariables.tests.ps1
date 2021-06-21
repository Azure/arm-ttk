﻿<#
.Synopsis
    Tests related to expansion
.Description
    Tests related to expanding an Azure Resource Manager Template.

    Expand-AzTemplate expands a resource manager template into a series of well-known variables
#>
param(
)

$here = Split-Path -Parent $MyInvocation.MyCommand.Path


Push-Location -Path "$here"

describe Expand-AzTemplate {
    context 'ExpandedVariables' {
        $expanded = Expand-AzTemplate -TemplatePath (Join-Path $pwd .\ExpandVariables.json)
        $expanded.ExpandedTemplateText | ?<ARM_Variable> | Should -Be $null
        $expanded.ExpandedTemplateObject.someProperty | Should -BeLike '*resourceGroup()*.location*'
    }
}

Pop-Location