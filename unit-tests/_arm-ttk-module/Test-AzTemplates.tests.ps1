<#
.Synopsis
    Tests for Test-AzTemplate
.Description
    Tests for core functionality of Test-AzTemplate.
#>

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Push-Location $here

describe AllFiles {
    it 'Can run tests on all files by passing -GroupName AllFiles' {
        $pwd | 
            Split-Path | 
            Join-Path -ChildPath Common | 
            Join-Path -ChildPath Pass | 
            Join-Path -ChildPath 100-marketplace-sample |
            Get-Item| 
            Test-AzTemplate -GroupName AllFiles -Test 'JSONFiles-Should-Be-Valid' | 
            Select-Object -ExpandProperty Passed | 
            Should -Be $true
    }
}
Pop-Location
