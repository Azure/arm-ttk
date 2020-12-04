<#
.Synopsis
    arm-ttk Pester tests
.Description
    Pesters tests for the Azure Resource Manager Template Toolkit (arm-ttk).

    These tests make sure arm-ttk is working properly, and are not to be confused with the validation within arm-ttk.
.Notes
    These tests will check the integrity of the module
    
#>

$here = Split-Path -Parent $MyInvocation.MyCommand.Path


Push-Location -Path "$here\..\..\arm-ttk"

$module = 'arm-ttk'
describe "arm-ttk Module Tests" {
  Context 'Checking module' {

    It "has the root module $module.psm1" {
       ".\$module.psm1" | Should Exist
    }

    It "has the a manifest file of $module.psm1" {
      ".\$module.psd1" | Should -Exist
      ".\$module.psd1" | Should -FileContentMatch "$module.psm1"
    }
    
    $files = (
      'Test-AzTemplate.ps1',
      'Test-AzTemplate.cmd',
      'Test-AzTemplate.sh'
    )
    
    foreach($file in $files){
      It "has file -> $file" {
        ".\$file" | Should -Exist
      }
    }
  } #Context 'Checking module'
   
  Set-Location -Path '.\testcases'

  # Ensure that all custom testcases meet minimum standard
  $cases = Get-ChildItem -File -Recurse -Filter '*.ps1'
  foreach($case in $cases){

    $file = $case | Split-Path -Leaf

    Context "Checking $file"  {
      It "$file is valid PowerShell code" {
        $psFile = Get-Content -Path $case -ErrorAction Stop
        $errors = $null
         $null = [System.Management.Automation.PSParser]::Tokenize($psFile, [ref]$errors)
         $errors.Count | Should -Be 0
      }
    
      It "$file should have help block" {
        $case | Should -FileContentMatch '<#'
        $case | Should -FileContentMatch '#>'
      }

      It "$file should have a SYNOPSIS section in the help block" {
        $case | Should -FileContentMatch '.SYNOPSIS'
      }
    
      It "$file should have a DESCRIPTION section in the help block" {
        $case | Should -FileContentMatch '.DESCRIPTION'
      }

      It "$file should have a EXAMPLE section in the help block" -Pending {
        $case | Should -FileContentMatch '.EXAMPLE'
      }
    } #Context "Checking $file"
  } #foreach $case
}

Pop-Location