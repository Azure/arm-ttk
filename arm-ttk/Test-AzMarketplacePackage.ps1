function Test-AzMarketplacePackage
{
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
        $PackagePath
    )

    $MarketplaceWarningTests = @(
        "CreateUIDefinition-Must-Not-Have-Blanks" ,

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
        "VM-Images-Should-Use-Latest-Version"
    )

    $WarningtestList = $MarketplaceWarningTests -join  ","

    $errors = Invoke-Command {
    ## Include all error tests here
    Test-AzTemplate $PackagePath -Skip $WarningtestList
    } -ArgumentList $PackagePath
    

    $warnings = Invoke-Command {
    ## Include all warning tests here
    Test-AzTemplate  $PackagePath -Tests $MarketplaceWarningTests
    } -ArgumentList $PackagePath


    # we need to be able to combine these 2 objects $errors and $warnings so as to show the errors and warnings as separate
    # i.e the sections need to be combined so that 
    #     1) the errors in the warnings variable show up as warnings i.e not in red but yellow 
    #     2) And the groups are merged for both variables , eg : CreateUidefinition group results for both should get combined together.

    if($errors.Passed -ne $true)
    {
        $errors
    }
    if($warnings.Passed -ne $true)
    {
        $warnings
    }
}