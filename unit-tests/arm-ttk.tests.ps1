<#
.Synopsis
    arm-ttk Pester tests
.Description
    Pesters tests for the Azure Resource Manager Template Toolkit (arm-ttk).

    These tests make sure arm-ttk is working properly, and are not to be confused with the validation within arm-ttk.
.Notes

    The majority of tests are implemented in a parallel directory structure to the validation in arm-tttk.
    
    That is, for each test file in deploymentTemplate, a test directory should exist beneath this location.

    For example, given the arm-ttk validation rule in:

        /arm-ttk/testcases/deploymentTemplate/adminUsername-Should-Not-Be-A-Literal.test.ps1

    There should be a test data directory in /unit-tests/:
        
        /unit-tests/adminUsername-Should-Not-Be-A-Literal

    
    This will map to a describe block named deploymentTemplate\adminUsername-Should-Not-Be-A-Literal

    This directory should contain two subfolders:

    * /unit-tests/adminUsername-Should-Not-Be-A-Literal/Pass
    * /unit-tests/adminUsername-Should-Not-Be-A-Literal/Fail

    ### The Pass Folder 
    The Pass folder can contain one or more JSON files or folders.
    Running these rules on these files should produce no errors.
    
    The Pass folder may also contain one or more .path.txt files.
    These will contain a relative path to a JSON file that should produce no errors.

    ### The Fail Folder

    The Fail folder may also contain one or more JSON files or folders.
    
    These JSON files are expected to produce errors.

    Each JSON file may have a corresponding .should.be.ps1 or .should.be.txt

    If the corresponding .should.be file is a text file (.txt), 
    the error message or ID should match the contents of the file.

    If the corresponding .should.be file is a script (.ps1),
    the error will be passed to the .ps1, which should throw if the error was unexpected. 
#>


if (-not (Get-Module arm-ttk)) { 
    Write-Error "arm-ttk not loaded"
    return
}

# We'll need a few functions to get started:
# Get-TTKPesterInput ( this gets the right input file, given the criteria above)
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

#Test-TTKPass is called for each directory of pass files, and contains the "it" block
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

$callstack = @(Get-PSCallStack)
if ($callstack.Length -gt 2) { return }

describe 'Format-AzTemplate' {
    it 'Sorts the format of an Azure Resource Manager Template' {
        $formatted = Format-AzTemplate -TemplateObject ([PSCustomObject]@{
            'parameters' = @{'foo'= @{defaultValue='bar'}}
            '$schema' = 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
        })

        @($formatted.psobject.properties)[0].name | should be '$schema'
    }
}

$PSScriptRoot | 
    Get-ChildItem -Recurse -Filter *.tests.ps1 | 
    Where-Object { $_.Name -ne $MyInvocation.InvocationName } |
    ForEach-Object { 
        & $_.FullName
    }