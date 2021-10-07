function Set-RuleID
{
    <#
    .Synopsis
        Sets the rule IDs
    .Description
        Returns a TargetObject for Write-Error that has a ruleID defined
    .Example
        Define-RuleID -RuleID "000006" -TargetObject <anObject>
        Define-RuleID -RuleID "000050"
    #>

    param(
        [string] $RuleID,
        [PSObject] $TargetObject
        )

    if(!$TargetObject) {
        $TargetObject = New-Object -Type PSObject -Property @{
                        'ruleID'   = $RuleID
                    }
    } else {
        $TargetObject | Add-Member -MemberType NoteProperty -Name ruleID -Value $RuleID -Force
    }

    return $TargetObject
}