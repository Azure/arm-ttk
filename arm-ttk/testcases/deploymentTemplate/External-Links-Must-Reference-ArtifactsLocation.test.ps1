<#
.Synopsis
    Ensures Deployments  do not link to external uris
.Description
    Ensures 
        - Resources of type Microsoft.Resources/deployments do not have their uri field set to external URIs
        - Resources of type Microsoft.Web/sites do not have their WEBSITE_RUN_FROM_PACKAGE set to external URIs
        - Resources of type Microsoft.Web/sites/extensions do not have thier packageuri field set to external URIs
#>

param(
# The Template Object
[Parameter(Mandatory)]
[PSObject]
$TemplateObject
)

$MarketplaceWarning = $false

$artifactslocationParameterExp = "*artifactsLocation*";
$artifactslocationSasTokenParameterExp = "*artifactsLocationSasToken*";



$deploymentResources = $TemplateObject.resources | 
    Find-JsonContent -Key type -Value 'Microsoft.Resources/deployments'
foreach ($dr in $deploymentResources) {
    $uri = $dr.properties.TemplateLink.uri
    if ($uri) {
        if ($uri -is [string] -and $uri -match '^\s{0,}\[') {
            $expanded = Expand-AzTemplate -Expression $uri -InputObject $TemplateObject
            $uri = $expanded
        }
        if ($uri -is [string] -and 
             ($uri -inotlike $artifactslocationParameterExp -or $uri -inotlike $artifactslocationSasTokenParameterExp)) {
            Write-TtkMessage -MarketplaceWarning $MarketplaceWarning "Deployment Resources must only link to artifacts location for thier uri field" -TargetObject $dr -ErrorId "External.Links.Must.Reference.ArtifactsLocation"
        }
    }
}

# For function app resources the WEBSITE_RUN_FROM_PACKAGE should have value as 1 or reference the artifacts location
$websiteResources =  $TemplateObject.resources | 
Find-JsonContent -Key type -Value 'Microsoft.Web/sites'
foreach ($wr in $websiteResources) {
    $settings = $wr.properties.siteConfig.appsettings
    foreach($setting in $settings) {
    if ($setting.name -eq "WEBSITE_RUN_FROM_PACKAGE") {
        $value = $setting.value

        if($value -eq 1)
        {
            continue;
        }

        if ($value -is [string] -and $value -match '^\s{0,}\[') {
            $expanded = Expand-AzTemplate -Expression $value -InputObject $TemplateObject
            $value = $expanded
        }

        if ($value -is [string] -and 
             ($value -inotlike $artifactslocationParameterExp -or $value -inotlike $artifactslocationSasTokenParameterExp)) {
            Write-TtkMessage -MarketplaceWarning $MarketplaceWarning "WEBSITE_RUN_FROM_PACKAGE must point to artifacts location" -TargetObject $dr -ErrorId "External.Links.Must.Reference.ArtifactsLocation"
        }
    }
    }
}

# The packages extensions links for websites must also only point to artifacts location.
$websiteExtensionResources= @();
if($websiteResources.resources)
{
    $websiteExtensionResources +=  $websiteResources.resources | 
    Find-JsonContent -Key type -Value 'extensions'
}
$websiteExtensionResources += $TemplateObject.resources | 
    Find-JsonContent -Key type -Value 'Microsoft.Web/sites/extensions'

foreach ($wr in $websiteExtensionResources) {
    $uri = $wr.properties.packageUri
    if ($uri) {
        if ($uri -is [string] -and $uri -match '^\s{0,}\[') {
            $expanded = Expand-AzTemplate -Expression $uri -InputObject $TemplateObject
            $uri = $expanded
        }
        if ($uri -is [string] -and 
             ($uri -inotlike $artifactslocationParameterExp -or $uri -inotlike $artifactslocationSasTokenParameterExp)) {
            Write-TtkMessage -MarketplaceWarning $MarketplaceWarning "Function package must only link to artifacts location for their uri field" -TargetObject $dr -ErrorId "External.Links.Must.Reference.ArtifactsLocation"
        }
    }
}