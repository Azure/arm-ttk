<#
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
        it 'Can expand variables' {
            $expanded = Expand-AzTemplate -TemplatePath (Join-Path $pwd ExpandVariables.json)
            $expanded.ExpandedTemplateText | ?<ARM_Variable> | Should -Be $null
            $expanded.ExpandedTemplateObject.someProperty | Should -Be '[resourceGroup().location]'
        }

        it 'Can expand subexpressions with quotes' {
            $expanded = Expand-AzTemplate -TemplatePath (Join-Path $pwd ExpandVariables.json)
            $expanded.ExpandedTemplateText | ?<ARM_Variable> | Should -Be $null
            $expanded.ExpandedTemplateObject.quoting | Should -BeLike '*"*"*' 
        }

        it 'Can embed nested objects' {
            $expanded = Expand-AzTemplate -TemplatePath (Join-Path $pwd ExpandVariables.json)
            $expanded.ExpandedTemplateText | ?<ARM_Variable> | Should -Be $null
            $expanded.ExpandedTemplateObject.obj | Should -Be '[json(''{"key":"value"})'']' 
        }
    }
}

Pop-Location