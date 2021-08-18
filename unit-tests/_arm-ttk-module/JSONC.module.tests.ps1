Push-Location $PSScriptRoot 

describe "JSONC" {
    it "Supports JSONC files" {        
        Test-AzTemplate -TemplatePath (Join-Path $pwd "Sample.jsonc") -Test 'DeploymentTemplate Schema Is Correct' -File "Sample.jsonc"  |
            Select-Object -ExpandProperty Passed | 
            Should -Be $true
    }
}

Pop-Location
