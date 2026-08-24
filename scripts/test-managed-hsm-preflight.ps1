[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [ValidatePattern("^[a-zA-Z0-9-]{3,24}$")]
  [string]$HsmName,

  [Parameter(Mandatory)]
  [ValidatePattern("^[a-zA-Z0-9-]{1,127}$")]
  [string]$SigningKeyName
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
  throw "Azure CLI is required. Install it and authenticate before running this preflight."
}

$account = az account show --output json | ConvertFrom-Json
if (-not $account.id) {
  throw "No active Azure subscription was found. Run 'az login' and select the intended subscription."
}

Write-Host "Validating Managed HSM '$HsmName' in subscription '$($account.id)'."
$hsm = az keyvault show --hsm-name $HsmName --output json | ConvertFrom-Json
if (-not $hsm.properties.enablePurgeProtection) {
  throw "Managed HSM purge protection is not enabled. Stop and investigate the deployment."
}

$key = az keyvault key show --hsm-name $HsmName --name $SigningKeyName --output json | ConvertFrom-Json
if ($key.key.kty -ne "RSA-HSM") {
  throw "Key '$SigningKeyName' is '$($key.key.kty)', not the expected RSA-HSM type."
}

$operations = @($key.key.keyOps)
if (("sign", "verify") | Where-Object { $_ -notin $operations }) {
  throw "Key '$SigningKeyName' does not permit both sign and verify operations."
}

Write-Host "Managed HSM URI: $($hsm.properties.hsmUri)"
Write-Host "Signing key ID: $($key.key.kid)"
Write-Host "Key enabled: $($key.attributes.enabled)"
Write-Host "Key operations: $($operations -join ', ')"
Write-Host "\nAssigned local HSM roles for this key:"
az keyvault role assignment list --hsm-name $HsmName --scope "/keys/$SigningKeyName" --output table

Write-Host "\nPreflight passed. Run signing clients only from a network that resolves the Managed HSM private endpoint."
