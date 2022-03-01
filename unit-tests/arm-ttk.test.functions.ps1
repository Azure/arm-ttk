<#
.Synopsis
    arm-ttk Pester tests
.Description
    Pesters tests for the Azure Resource Manager Template Toolkit (arm-ttk).

    These tests make sure arm-ttk is working properly, and are not to be confused with the validation within arm-ttk.

    Get-TTKPesterInput ( this gets the right input file, given the criteria above)
#>

function Get-TTKPesterTestInput {
    param(
    [Parameter(Mandatory)]
    [string]
    $Path
    )
    Push-Location $path  # Push into the path so relative paths work as expected.
    foreach ($item in Get-ChildItem -Path $Path) {
        
        if ($item.Extension -eq '.json') {
            $item
        }
        elseif ($item.Name -match '\.path\.txt$') {
            foreach ($line in [IO.File]::ReadAllLines($item.Fullname)) {
                Get-Item -Path $line -ErrorAction SilentlyContinue
            }
        }
        elseif ($item -is [IO.DirectoryInfo]) {
            $item
        }
    }
    Pop-Location
}

function Test-TTK{
    param(
    [Parameter(Mandatory)]
    [string]
    $Path
    )

    $directoryName = $Path | Split-Path -Leaf
    Push-Location $Path

    describe $directoryName {
        $failDirectory = Get-ChildItem -Filter Fail -ErrorAction Ignore

        if ($failDirectory) { # If the fail directory is present, run fail
            context 'Fail' { 
                Test-TTKFail -Name $directoryName -Path $failDirectory.FullName
            }
        }

        $passDirectory = Get-ChildItem -Filter Pass -ErrorAction Ignore
        if ($passDirectory) { # If the pass directory is present, run pass
            context 'Pass' {
                Test-TTKPass -Name $directoryName -Path $passdirectory.FullName
                
            }
        }    
    }

    Pop-Location


}


function Test-TTKPass {
    param(
    [Parameter(Mandatory)]
    [string]
    $Name,

    [Parameter(Mandatory)]
    [string]
    $Path
    )
    $testFiles = Get-TTKPesterTestInput -Path $path 
    foreach ($testFile in $testFiles) {
        $fileName = $testFile.Name.Substring(0, $testFile.Name.Length - $testFile.Extension.Length)
        $ttkParams = @{Test = $Name}
        if ($testFile -isnot [IO.DirectoryInfo]) {
            $ttkParams.File = $testfile.Name
        }
        it "Validates $fileName is correct" {
            
            $ttkResults = Get-Item -Path $testFile.Fullname | 
                Test-AzTemplate @ttkParams
            if ($DebugPreference -in 'inquire', 'continue') {
                $ttkResults | Out-Host
            }
            if (-not $ttkResults) { throw "No Test Results" }
            if ($ttkResults | Where-Object { -not $_.Passed}) {
                throw "$($ttkResults.Errors | Out-String)"
            }
        }
    }

}

function Test-TTKFail {
    param(
    [Parameter(Mandatory)]
    [string]
    $Name,

    [Parameter(Mandatory)]
    [string]
    $Path
    )

    $testFiles = Get-TTKPesterTestInput -Path $Path
    foreach ($testFile in $testFiles) {
        $fileName = $testFile.Name.Substring(0, $testFile.Name.Length - $testFile.Extension.Length)
        $targetTextPath  = Join-Path $path "$fileName.should.be.txt"
        $targetScriptPath = Join-Path $path "$fileName.should.be.ps1"
        it "Validates $fileName is flagged" {
            $ttkParams = @{Test = $Name}
            if ($testFile -isnot [IO.DirectoryInfo]) {
                $ttkParams.File = $testfile.Name
            }
            $ttkResults = Get-Item -Path $testFile.Fullname | 
                Test-AzTemplate @ttkParams 
            if (-not $ttkResults) { throw "No Test Results" }
            if ($DebugPreference -in 'inquire', 'continue') {
                $ttkResults | Out-Host
            }
            if (-not ($ttkResults | Where-Object {$_.Errors })) {
                throw 'Errors were expected'
            }
            if (Test-Path $targetTextPath) { # If we have a .should.be.txt
                $targetText = [IO.File]::ReadAllText($targetTextPath).Trim() # read it
                foreach ($ttkResult in $ttkResults) {
                    foreach ($ttkError in $ttkResult.Errors) {
                        if ($ttkError.Message -ne $targetText -and $ttkError.FullyQualifiedErrorID -notlike "$targetText,*") {
                            throw "Unexpected Error:
Expected '$($targetText)', got $($ttkError.Message)
$(if ($ttkError.FullyQualifiedErrorID -notlike 'Microsoft.PowerShell*') {
    'ErrorID [' + $ttkError.FullyQualifiedErrorID.Split(',')[0] + ']'
})"
                        }
                    }   
                }
            }
            if (Test-Path $targetScriptPath) {
                
                & "$targetScriptPath" $ttkResults
            }
            
        }
    }
}
