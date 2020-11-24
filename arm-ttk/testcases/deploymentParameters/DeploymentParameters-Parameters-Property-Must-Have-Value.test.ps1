<#
.Synopsis
    Ensures that parameters have a value
.Description
    Ensures that all parameters have a property 'value'
#>
param(
  # The Template Object
  [Parameter(Mandatory = $true, Position = 0)]
  [PSObject]
  $TemplateObject
)

Write-Debug $TemplateObject.parameters
foreach ($p in $TemplateObject.parameters.psobject.properties) {
    
  # If the parameter name starts with two underscores,
  if ($p.Name -like '__*') { continue } # skip it.

  # check if the property exist on the hashtable Value property for the key 'value'
  if ( -not ($p.Value.PsObject.Properties.match('value').Count -or $p.Value.PsObject.Properties.match('reference').Count )) {
    Write-Error -ErrorId Parameters.Parameter.Missing.Value -Message "'$($p.Name)' must have a property 'value' or 'reference'" -TargetObject $p.Value 
    continue
  }

  if ( $p.Value.PsObject.Properties.match('value').Count){     
    continue
  }

  if( $p.Value.PsObject.Properties.match('reference').Count){
    $kvRef = $p.Value.reference 
    if(-not $kvRef.PsObject.Properties.match('keyVault').Count){
      Write-Error -ErrorId Parameters.Parameter.Missing.Value -Message "'$($p.Name)'.reference is missing have a property 'keyVault'" -TargetObject $p.Value.reference
      continue
    }
    else {
      $kv = $kvRef.keyVault;
      if(-not $kv.PsObject.Properties.match('id').Count){
        Write-Error -ErrorId Parameters.Parameter.Missing.KeyVault.Id -Message "'$($p.Name)'.reference is missing have a property 'keyVault'" -TargetObject $p.Value.reference.keyVault
        continue
      }
      # Resource Group naming restrictions, ref: https://github.com/toddkitta/azure-content/blob/master/articles/guidance/guidance-naming-conventions.md
      # Keyvalut naming restrictions, ref: https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules#microsoftkeyvault
      elseif($kv.id -inotmatch '/subscriptions/([0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12})/resourceGroups/([\w\d_-]{1,64})/providers/Microsoft.KeyVault/vaults/([\w\d-]{3,24})') {
        Write-Error -ErrorId Parameters.Parameter.Bad.KeyVault.Id -TargetObject $p.Value.reference.keyVault.id -Message "'$($p.Name)'.reference.keyValut.id contains improper value, `r`n Should be like : /subscriptions/<subscription id>/resourceGroups/<resource group name>/providers/Microsoft.KeyVault/vaults/<key vault name>"
        continue
      }
    }
    if(-not $kvRef.PsObject.Properties.match('secretName').Count){
      Write-Error -ErrorId Parameters.Parameter.Missing.SecretName -Message "'$($p.Name)'.reference is missing have a property 'secretName'" -TargetObject $p.Value.reference
      continue
    }
    
    if($kvRef.secretName -inotmatch '^([A-Za-z0-9\-]{1,127})$'){
      Write-Error -ErrorId Parameters.Parameter.Bad.SecretName -TargetObject $kvRef.secretName -Message "'$($p.Name)'.reference.secretName should only contain alphanumeric caracters or dashes and be between 1 and 127 in length, `r`n Found: $($kvRef.secretName)"
      continue
    }
  }
}