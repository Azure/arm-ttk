function Test-AzMarketplacePackage {
    <#    
    .Synopsis
Runs the tests for a marketplace package.
    .Description
Validates a package for publishing on the azure marketplace.
    .Notes
Test-AzMarketplacePackage validates a package to verify if it passes all the minimum required tests to be published in the azure marketplace.

    .Example
        Test-AzMarketplacePackage -TemplatePath ./FolderWithPackage
        # Tests Marketplace package in /FolderWithPackage
  
#>

    param (
        [string]
        $templatePath
    )

    # these are the tests that should only show a warning, we don't block Marketplace submissions on these tests
    # below we will run the TTK twice, once with the set of tests that are warnings and then once exclude these warning test
    $MarketplaceWarningTests = @(
        "CreateUIDefinition-Must-Not-Have-Blanks",
        "apiVersions-Should-Be-Recent-In-Reference-Functions",
        "apiVersions-Should-Be-Recent",
        "DependsOn-Best-Practices",
        "DeploymentTemplate-Schema-Is-Correct",
        "Dynamic-Variable-References-Should-Not-Use-Concat",
        "IDs-Should-Be-Derived-From-ResourceIDs",
        "ManagedIdentityExtension-must-not-be-used",
        "Parameters-Must-Be-Referenced",
        "providers_apiVersions-Is-Not-Permitted",
        "ResourceIds-should-not-contain",
        "Template-Should-Not-Contain-Blanks",
        "VM-Images-Should-Use-Latest-Version",
        "Variables-Must-Be-Referenced",
        "URIs-Should-Be-Properly-Constructed"
    )

    # these tests should only trigger a warning, not a "failure"
    $ttkWarnings = Test-AzTemplate  $templatePath -Tests $MarketplaceWarningTests

    # All other tests should trigger a true test "failure"
    $ttkErrors = Test-AzTemplate $templatePath -Skip $MarketplaceWarningTests
    

    # we need to be able to combine these 2 objects $errors and $ttkWarnings so as to show the errors and warnings as separate
    # i.e the sections need to be combined so that 
    #     1) the errors in the warnings variable show up as warnings i.e not in red but yellow 
    #     2) And the groups are merged for both variables , eg : CreateUidefinition group results for both should get combined together.

    $ttkErrors

    Write-Host "Please fix any failed tests flagged above. All failed tests must be fixed before submission."
    Write-Host "In addition please review the warnings below and fix them. It is highly recommended to fix these to ensure your customers are able to use your application without issues."
    Write-Host "For details on fixing these, please check https://aka.ms/arm-ttk-docs"    

    $ttkWarnings  | Where-Object Errors | ForEach-Object {
        $_.Warnings = @(foreach ($err in $_.Errors) {
                Write-Warning -Message "$err" *>&1
            })
        $_.Errors = @()
        $_.AllOutput = @(
            foreach ($eachOutput in $_.AllOutput) {
                if ($eachOutput -is [Management.Automation.ErrorRecord]) {
                    Write-Warning -Message "$eachOutput" *>&1
                }
                else {
                    $eachOutput
                }
            }
        )
        $_
    }
}
