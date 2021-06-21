<#
.Synopsis
    Installs Pester
.Description
    Installs Pester
#>
param(
# The maximum pester version.  Defaults to 4.99.99.
[string]
$PesterMaxVersion = '4.99.99'
)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-Module -Name Pester -Repository PSGallery -Force -Scope CurrentUser -MaximumVersion $PesterMaxVersion -SkipPublisherCheck -AllowClobber
Import-Module Pester -Force -PassThru -MaximumVersion $PesterMaxVersion