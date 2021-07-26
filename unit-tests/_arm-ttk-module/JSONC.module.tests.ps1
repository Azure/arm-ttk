Push-Location $PSScriptRoot 

describe "JSONC" {
    it "Supports JSONC files" {
        Test-AzTemplate -TemplatePath (Join-Path $pwd "Sample.jsonc") -Test 'DeploymentTemplate Schema Is Correct' |
            Select-Object -ExpandProperty Passed | 
            Should -Be $true
    }
}

Pop-Location
