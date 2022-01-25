
$global:MarketplaceMode = $false

function Write-TtkMessage
{
    <#
    .Synopsis
        Logs the message as an error or a warning.

    .Description
        Test files can use this function to log a message as either a warning or an error.

    .Notes
        This function must be used for all logging operations in the tests.
    #>
    [OutputType([string],[PSObject])]
    param(
        
    # The message to be logged
    [Parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true)]
    [string]
    $Message,

    # The error level to log the message.
    [Parameter(Mandatory=$false,Position=1,ValueFromPipelineByPropertyName=$true)]
    [bool]
    $MarketplaceWarning = $false,

    # The target object for the error.
    [Parameter(Mandatory=$false,Position=2,ValueFromPipelineByPropertyName=$true)]
    [object]
    $TargetObject,

    # The error id for the error.
    [Parameter(Mandatory=$false,Position=3,ValueFromPipelineByPropertyName=$true)]
    [string]
    $ErrorId)

    if($MarketplaceWarning -eq $true -and $global:MarketplaceMode -eq $true)
    {
        Write-Warning $Message
    }
    else
    {
        Write-Error -Message $Message -TargetObject $TargetObject -ErrorId $ErrorId
    }
}
