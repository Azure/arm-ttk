# Cross-Tenant Deployment Guide

## Overview

This template is designed to work **across tenants** by removing the Key Vault dependency and fetching the SAS token directly from your configuration API.

## Key Changes from Previous Version

### ❌ Removed
- Key Vault dependency (was tenant-specific)
- Hardcoded managed identity resource ID
- Cross-subscription references

### ✅ Added
- SAS token fetched directly from configuration API
- Uses managed identity from deployment parameters
- Fully tenant-agnostic

## Configuration API Response

Your API at `https://wowcentral.azurewebsites.net/api/deployment-config` must now return:

```json
{
  "blobName": "BELinux.1.8.500.zip",
  "container": "latest",
  "sasToken": "sp=r&st=2025-11-03T13:00:00Z&se=2037-11-04T01:00:00Z&spr=https&sv=2024-11-04&sr=b&sig=4A1%2FetYWbaQksdhhujIj9LeWALfMqPiWSnZl6yhM5lA%3D",
  "version": "1.8.500",
  "releaseNotes": "https://releases.worldofworkflows.com/1.8.500/notes"
}
```

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `blobName` | string | Name of the ZIP file (e.g., `BELinux.1.8.500.zip`) |
| `container` | string | Blob storage container name (e.g., `latest`) |
| `sasToken` | string | SAS token for accessing the blob (without leading `?`) |

### Optional Fields

| Field | Type | Description |
|-------|------|-------------|
| `version` | string | Version number for logging |
| `releaseNotes` | string | URL to release notes |
| `environment` | string | Target environment |

## How SAS Tokens Work Cross-Tenant

SAS tokens are **tenant-agnostic** because they are:

1. **Signed URLs** - The signature is cryptographic proof of authorization
2. **Self-contained** - All permissions are in the token itself
3. **No authentication required** - Anyone with the token can access the resource
4. **Time-limited** - They expire automatically

```
https://wowreleases.blob.core.windows.net/latest/BELinux.1.8.500.zip?sp=r&st=2025-11-03...
     ↑                                        ↑                      ↑
   Storage Account                       Blob Path              SAS Token
   (any tenant)                       (public or private)    (grants access)
```

## Deployment Flow

```
┌─────────────────┐
│  Any Tenant     │
│  Any Subscription│
└────────┬────────┘
         │
         ↓
┌─────────────────────────────────┐
│  ARM Template Deployment        │
│  - Uses local managed identity  │
│  - Creates Entra ID apps        │
└────────┬────────────────────────┘
         │
         ↓
┌─────────────────────────────────┐
│  GetDeploymentConfig Script     │
│  Calls Configuration API →      │
└────────┬────────────────────────┘
         │
         ↓
┌─────────────────────────────────┐
│  Configuration API              │
│  https://wowcentral...          │
│  Returns: blob name + SAS token │
└────────┬────────────────────────┘
         │
         ↓
┌─────────────────────────────────┐
│  DeployZipPackage Script        │
│  Downloads from blob storage    │
│  using SAS token                │
└────────┬────────────────────────┘
         │
         ↓
┌─────────────────────────────────┐
│  Deployment Complete            │
│  Notification sent to API       │
└─────────────────────────────────┘
```

## Setup Per Tenant

Each tenant needs a managed identity with permission to create Entra ID applications.

### 1. Create Managed Identity

```bash
# In each tenant/subscription
az identity create \
  --name WoWBEInstaller \
  --resource-group <your-resource-group> \
  --location <region>
```

### 2. Grant Azure AD Permissions

The managed identity needs permission to create applications:

```bash
# Get the managed identity's principal ID
PRINCIPAL_ID=$(az identity show \
  --name WoWBEInstaller \
  --resource-group <your-resource-group> \
  --query principalId -o tsv)

# Grant Application.ReadWrite.All permission
# This must be done by a Global Administrator
az ad app permission add \
  --id $PRINCIPAL_ID \
  --api 00000003-0000-0000-c000-000000000000 \
  --api-permissions 1bfefb4e-e0b5-418b-a88f-73c46d2cc8e9=Role

# Admin consent required
az ad app permission admin-consent --id $PRINCIPAL_ID
```

### 3. Pass to Template

When deploying, pass the managed identity in the `managedIdentityName` parameter (handled by `createUiDefinition.json`).

## Configuration API Implementation

### Example: Simple Static Response

```csharp
[ApiController]
[Route("api")]
public class DeploymentConfigController : ControllerBase
{
    [HttpGet("deployment-config")]
    public IActionResult GetConfig()
    {
        // Read from configuration or database
        var config = new
        {
            blobName = "BELinux.1.8.500.zip",
            container = "latest",
            sasToken = "sp=r&st=2025-11-03T13:00:00Z&se=2037-11-04T01:00:00Z...",
            version = "1.8.500",
            releaseNotes = "https://releases.worldofworkflows.com/1.8.500/notes"
        };

        return Ok(config);
    }
}
```

### Example: Environment-Based Routing

```csharp
[HttpGet("deployment-config")]
public IActionResult GetConfig([FromQuery] string environment = "production")
{
    var sasToken = _configuration[$"SasTokens:{environment}"];
    var version = _configuration[$"Versions:{environment}"];
    
    return Ok(new
    {
        blobName = $"BELinux.{version}.zip",
        container = "latest",
        sasToken = sasToken,
        version = version,
        environment = environment
    });
}
```

### Example: Tenant-Based Routing

```csharp
[HttpGet("deployment-config")]
public IActionResult GetConfig([FromHeader(Name = "X-Tenant-Id")] string tenantId)
{
    // Look up tenant-specific configuration
    var tenantConfig = _db.TenantConfigs
        .Where(t => t.TenantId == tenantId)
        .FirstOrDefault();
    
    if (tenantConfig == null)
    {
        // Return default
        tenantId = "default";
        tenantConfig = _db.TenantConfigs
            .Where(t => t.TenantId == "default")
            .FirstOrDefault();
    }
    
    return Ok(new
    {
        blobName = tenantConfig.BlobName,
        container = tenantConfig.Container,
        sasToken = tenantConfig.SasToken,
        version = tenantConfig.Version
    });
}
```

## SAS Token Management

### Generating SAS Tokens

```bash
# Generate a SAS token for blob storage
az storage blob generate-sas \
  --account-name wowreleases \
  --container-name latest \
  --name BELinux.1.8.500.zip \
  --permissions r \
  --expiry 2037-11-04T01:00:00Z \
  --https-only \
  --output tsv
```

### Best Practices

1. **Long expiration** - Use multi-year expiration (SAS tokens can't be revoked)
2. **Read-only** - Use `sp=r` (read permission only)
3. **HTTPS only** - Always use `spr=https`
4. **Account SAS** - Can create one SAS for multiple blobs
5. **Store securely** - Keep SAS tokens in configuration API, not in public repos

### Rotating SAS Tokens

When you need to rotate:

1. Generate new SAS token
2. Update configuration API to return new token
3. Keep old token active for overlap period (e.g., 30 days)
4. After all deployments updated, remove old token from API

## Deployment Examples

### Deploy to Tenant A

```bash
az deployment group create \
  --resource-group TenantA-RG \
  --template-file mainTemplate-cross-tenant.json \
  --parameters @createUiDefinition.json \
  --parameters managedIdentityName='{"type":"UserAssigned","userAssignedIdentities":{"/subscriptions/xxx/resourceGroups/TenantA-RG/providers/Microsoft.ManagedIdentity/userAssignedIdentities/WoWBEInstaller":{}}}'
```

### Deploy to Tenant B

```bash
az deployment group create \
  --resource-group TenantB-RG \
  --template-file mainTemplate-cross-tenant.json \
  --parameters @createUiDefinition.json \
  --parameters managedIdentityName='{"type":"UserAssigned","userAssignedIdentities":{"/subscriptions/yyy/resourceGroups/TenantB-RG/providers/Microsoft.ManagedIdentity/userAssignedIdentities/WoWBEInstaller":{}}}'
```

## Troubleshooting

### Error: "Failed to fetch config from URL"

**Cause**: Configuration API is unreachable or returned invalid JSON

**Fix**:
1. Test the API manually: `curl https://wowcentral.azurewebsites.net/api/deployment-config`
2. Ensure API returns valid JSON with required fields
3. Check network connectivity from Azure deployment environment

### Error: "No SAS token in configuration response"

**Cause**: API response missing `sasToken` field

**Fix**: Update API to include `sasToken` in response

### Error: "Failed to access package at URL"

**Cause**: SAS token is invalid or expired

**Fix**:
1. Generate new SAS token
2. Update configuration API
3. Test blob access: `curl -I "https://wowreleases.blob.core.windows.net/latest/BELinux.1.8.500.zip?<sas-token>"`

### Error: "Permission to perform action Microsoft.ManagedIdentity/userAssignedIdentities/assign/action"

**Cause**: Deploying user doesn't have permission to use managed identities

**Fix**:
```bash
az role assignment create \
  --role "Managed Identity Operator" \
  --assignee <user-object-id> \
  --scope <resource-group-scope>
```

### Error: Entra ID app creation fails

**Cause**: Managed identity doesn't have permission to create applications

**Fix**: Grant `Application.ReadWrite.All` permission (requires Global Admin)

## Security Considerations

### Configuration API

✅ **DO:**
- Use HTTPS only
- Implement rate limiting
- Log all requests
- Validate request origin
- Use authentication (optional but recommended)

❌ **DON'T:**
- Expose in public repos
- Return sensitive data beyond SAS tokens
- Allow unlimited requests

### SAS Tokens

✅ **DO:**
- Use read-only permissions (`sp=r`)
- Use HTTPS-only (`spr=https`)
- Set reasonable expiration (1-5 years)
- Monitor blob access logs

❌ **DON'T:**
- Use write permissions
- Share tokens publicly
- Use account keys instead

### Managed Identities

✅ **DO:**
- Use user-assigned identities
- Grant minimum permissions
- Create one per tenant
- Document permissions

❌ **DON'T:**
- Share across tenants
- Grant Owner or Contributor
- Use system-assigned for deployment scripts

## Comparison: Previous vs. New Architecture

### Previous (Single Tenant)

```
Deployment → Key Vault (Tenant A) → SAS Token → Blob Storage
                ↑
         Hardcoded subscription ID
         Won't work in Tenant B
```

**Issues:**
- ❌ Requires Key Vault in each tenant
- ❌ Hardcoded subscription/tenant references
- ❌ Can't deploy cross-tenant
- ❌ Requires Key Vault permissions

### New (Cross-Tenant)

```
Deployment → Config API (Anywhere) → SAS Token → Blob Storage
                    ↑
            Works from any tenant
            SAS token is tenant-agnostic
```

**Benefits:**
- ✅ Single configuration API for all tenants
- ✅ SAS token works everywhere
- ✅ No Key Vault required per tenant
- ✅ Easy version management
- ✅ No cross-tenant permissions needed

## Migration from Previous Version

If you're upgrading from the Key Vault version:

1. **Set up configuration API** with SAS token endpoint
2. **Test API** returns correct response format
3. **Deploy new template** - it will fetch from API instead of Key Vault
4. **Verify deployment** succeeds
5. **Decommission Key Vault** (optional, keep as backup)

No data migration needed - just switch templates!

## Summary

This cross-tenant architecture:

✅ Works in **any tenant** without pre-configuration  
✅ Uses **SAS tokens** for blob access (tenant-agnostic)  
✅ Fetches config from **central API** (single source of truth)  
✅ Requires only **managed identity** per tenant (for AD app creation)  
✅ Sends **deployment notifications** with full logs  
✅ Supports **version management** via API  

You can now deploy to unlimited tenants with the same template!
