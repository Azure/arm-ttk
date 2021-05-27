<#
.Synopsis
    Ensures that parameters have a value
.Description
    Ensures that all parameters have a property 'value'
.link
    https://github.com/toddkitta/azure-content/blob/master/articles/guidance/guidance-naming-conventions.md
.link
    https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules#microsoftkeyvault
#>
param(
  # The parameter Object
  [Parameter(Mandatory = $true, Position = 0)]
  [PSObject]
  $ParameterObject
)

# Skipping this when using key/value format, i.e. '$schemaless'
if (-not $ParameterObject.'$schema') {
  return
}

foreach ($p in $ParameterObject.parameters.psobject.properties) {
    
  # If the parameter name starts with two underscores,
  if ($p.Name -like '__*') { continue } # skip it.

  # check if the property exist on the hashtable Value property for the key 'value'
  # just checking if the property is there might result in false negative, for example if the property contains:  $null, 0, False, empty string
  if ( -not ($p.Value.PsObject.properties["value"] -or $p.Value.PSObject.properties["reference"])) {
    Write-Error -ErrorId Parameters.Parameter.Missing.Value -Message "'$($p.Name)' must have a property 'value' or 'reference'    
    n.b.  properties starting with '__' are ignored" -TargetObject $p.Value 
    continue
  }

  # just checking if the property is there might result in false negative, for example if the property contains:  $null, 0, False, empty string
  if ( $p.Value.PsObject.Properties["value"]){     
    if($p.Value.value -imatch '^\s?\[.*\]\s?$'){
      # TODO: if we add a blacklist of ARM expressions, we can flip this to an error - otherwise something like "[key()]" is a valid parameter and won't be evaulated by ARM
      Write-Warning -Message "'$($p.Name)'.value will not be evaluated as an expression" -TargetObject $p.Value.value
    }
    continue
  }

  if( $p.Value.PsObject.Properties["reference"]){
    $kvRef = $p.Value.reference 
    if(-not $kvRef.PsObject.Properties["keyVault"]){
      Write-Error -ErrorId Parameters.Parameter.Missing.Value -Message "'$($p.Name)'.reference is missing have a property 'keyVault'" -TargetObject $p.Value.reference
      continue
    }
    else {
      $kv = $kvRef.keyVault;
      if(-not $kv.PsObject.Properties["id"]){
        Write-Error -ErrorId Parameters.Parameter.Missing.KeyVault.Id -Message "'$($p.Name)'.reference is missing have a property 'keyVault'" -TargetObject $p.Value.reference.keyVault
        continue
      }
      # Resource Group naming restrictions, ref: https://github.com/toddkitta/azure-content/blob/master/articles/guidance/guidance-naming-conventions.md
      # Key Vault naming restrictions, ref: https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules#microsoftkeyvault
      elseif($kv.id -inotmatch '/subscriptions/([0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12})/resourceGroups/([\w\d_-]{1,64})/providers/Microsoft.KeyVault/vaults/([\w\d-]{3,24})') {
        Write-Error -ErrorId Parameters.Parameter.Bad.KeyVault.Id -TargetObject $p.Value.reference.keyVault.id -Message "'$($p.Name)'.reference.keyVault.id contains improper value, `r`n Should be like : /subscriptions/<subscription id>/resourceGroups/<resource group name>/providers/Microsoft.KeyVault/vaults/<key vault name>"
        continue
      }
    }
    if(-not $kvRef.PsObject.Properties["secretName"]){
      Write-Error -ErrorId Parameters.Parameter.Missing.SecretName -TargetObject $p.Value.reference -Message "'$($p.Name)'.reference is missing have a property 'secretName'"
      continue
    }
    
    if($kvRef.secretName -notmatch '^([A-Za-z0-9\-]{1,127})$'){
      Write-Error -ErrorId Parameters.Parameter.Bad.SecretName -TargetObject $kvRef.secretName -Message "'$($p.Name)'.reference.secretName should only contain alphanumeric caracters or dashes and be between 1 and 127 in length, `r`n Found: $($kvRef.secretName)"
      continue
    }
  }
}
