[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string]$ResourceGroupName,

  [Parameter(Mandatory)]
  [ValidatePattern("^[a-zA-Z0-9-]{3,23}$")]
  [string]$CloudHsmName,

  [string]$PrivateEndpointName = ""
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
  throw "Azure CLI is required. Install it and authenticate before running this preflight."
}

$account = az account show --output json | ConvertFrom-Json
if (-not $account.id) {
  throw "No active Azure subscription was found. Run 'az login' and select the intended subscription."
}

if ([string]::IsNullOrWhiteSpace($PrivateEndpointName)) {
  $PrivateEndpointName = "pep-$CloudHsmName"
}

$cloudHsm = az resource show `
  --resource-group $ResourceGroupName `
  --resource-type "Microsoft.HardwareSecurityModules/cloudHsmClusters" `
  --name $CloudHsmName `
  --api-version "2025-03-31" `
  --output json | ConvertFrom-Json

if ($cloudHsm.properties.publicNetworkAccess -ne "Disabled") {
  throw "Cloud HSM public network access is '$($cloudHsm.properties.publicNetworkAccess)', not Disabled."
}

if (-not $cloudHsm.identity.userAssignedIdentities) {
  throw "Cloud HSM has no user-assigned managed identity for backup and restore operations."
}

$privateEndpoint = az network private-endpoint show `
  --resource-group $ResourceGroupName `
  --name $PrivateEndpointName `
  --output json | ConvertFrom-Json

$connectionState = $privateEndpoint.privateLinkServiceConnections[0].privateLinkServiceConnectionState.status
if ($connectionState -ne "Approved") {
  throw "Cloud HSM private endpoint connection state is '$connectionState', not Approved."
}

Write-Host "Cloud HSM: $($cloudHsm.id)"
Write-Host "Public network access: $($cloudHsm.properties.publicNetworkAccess)"
Write-Host "Backup identity: $($cloudHsm.identity.userAssignedIdentities.PSObject.Properties.Name -join ', ')"
Write-Host "Private endpoint: $($privateEndpoint.id)"
Write-Host "Private endpoint connection: $connectionState"
Write-Host "Preflight passed. Initialize Cloud HSM only from an approved private-network administration host."
