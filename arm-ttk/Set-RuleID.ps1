function Set-RuleID
{
    <#
    .Synopsis
        Sets the rule IDs
    .Description
        Returns a TargetObject for Write-Error that has a RuleID defined
    .Example
        Define-RuleID -RuleIDStart "BP-1-" -RuleNumber 2 -TargetObject <anObject>
        Define-RuleID -RuleIDStart "BP-6-" -RuleNumber 1
    #>

    param(
        [string] $RuleIDStart,
        [int] $RuleNumber,
        [PSObject] $TargetObject
        )

    $newRuleID = $RuleIDStart + $RuleNumber

    if(!$TargetObject) {
        $TargetObject = New-Object -Type PSObject -Property @{
                        'ruleID'   = $newRuleID
                    }
    } else {
        $TargetObject | Add-Member -MemberType NoteProperty -Name ruleID -Value $newRuleID -Force
    }

    return $TargetObject
}