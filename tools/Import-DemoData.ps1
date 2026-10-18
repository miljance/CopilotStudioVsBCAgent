<#
.SYNOPSIS
Imports and applies the demo RapidStart packages of the Project Billing Agent.

.DESCRIPTION
Imports and applies PBA-1-SETUP, PBA-2-MASTER, PBA-3-PROJECTS and PBA-4-USAGE, in that order, through the
configurationPackages API. Install the app first: the projects use its fields.

The packages can be applied again at any time: master data and projects are updated to the package values. Only
PBA-4-USAGE creates new work: it puts the usage lines into the project journal PROJECT / BILLING, where you post them.
Once they are posted, applying PBA-4-USAGE again brings the same lines back and posting them again doubles the usage, so
use -SkipUsage after the first time (or create a new company).

Needs the Azure CLI signed in to the tenant (az account get-access-token).

.EXAMPLE
./tools/Import-DemoData.ps1 -Tenant <tenant id>

.EXAMPLE
./tools/Import-DemoData.ps1 -Tenant <tenant id> -SkipUsage
#>
param(
    [Parameter(Mandatory)] [string] $Tenant,
    [string] $Environment = 'bc29',
    [string] $Company = 'CopilotStudioVsBCAgent',
    [string] $PackageFolder = (Join-Path $PSScriptRoot '..\demo'),
    [switch] $SkipUsage
)
$ErrorActionPreference = 'Stop'
$packages = 'PBA-1-SETUP', 'PBA-2-MASTER', 'PBA-3-PROJECTS'
if (-not $SkipUsage) { $packages += 'PBA-4-USAGE' }

function Get-AuthHeader {
    @{ Authorization = "Bearer $(az account get-access-token --resource https://api.businesscentral.dynamics.com --tenant $Tenant --query accessToken -o tsv)" }
}
$api = "https://api.businesscentral.dynamics.com/v2.0/$Tenant/$Environment/api"
$companyId = ((Invoke-RestMethod "$api/v2.0/companies" -Headers (Get-AuthHeader)).value | Where-Object name -eq $Company).id
if (-not $companyId) { throw "Company $Company not found." }
$auto = "$api/microsoft/automation/v2.0/companies($companyId)/configurationPackages"
$anyVersion = @{ 'If-Match' = '*' }

foreach ($code in $packages) {
    $existing = (Invoke-RestMethod "$auto`?`$filter=code eq '$code'" -Headers (Get-AuthHeader)).value
    if ($existing) { Invoke-RestMethod "$auto($($existing.id))" -Method Delete -Headers ((Get-AuthHeader) + $anyVersion) | Out-Null }
    $package = Invoke-RestMethod $auto -Method Post -Headers (Get-AuthHeader) -ContentType 'application/json' -Body (@{ code = $code; packageName = $code } | ConvertTo-Json)
    $bytes = [System.IO.File]::ReadAllBytes((Join-Path $PackageFolder "$code.rapidstart"))
    Invoke-RestMethod "$auto($($package.id))/file('$code')/content" -Method Patch -Headers ((Get-AuthHeader) + $anyVersion) -ContentType 'application/octet-stream' -Body $bytes | Out-Null

    Invoke-RestMethod "$auto($($package.id))/Microsoft.NAV.import" -Method Post -Headers (Get-AuthHeader) | Out-Null
    do { Start-Sleep -Seconds 5; $state = Invoke-RestMethod "$auto($($package.id))" -Headers (Get-AuthHeader) } while ($state.importStatus -in 'InProgress', 'Scheduled')
    Write-Host "$code import: $($state.importStatus) ($($state.numberOfRecords) records)"
    if ($state.importStatus -ne 'Completed') { throw "$code import failed: $($state.importError)" }

    Invoke-RestMethod "$auto($($package.id))/Microsoft.NAV.apply" -Method Post -Headers (Get-AuthHeader) | Out-Null
    do { Start-Sleep -Seconds 5; $state = Invoke-RestMethod "$auto($($package.id))" -Headers (Get-AuthHeader) } while ($state.applyStatus -in 'InProgress', 'Scheduled')
    Write-Host "$code apply: $($state.applyStatus), errors: $($state.numberOfErrors)"
    if ($state.applyStatus -ne 'Completed') { throw "$code apply failed: $($state.applyError)" }
    if ($state.numberOfErrors -gt 0) {
        Write-Warning "$code has $($state.numberOfErrors) errors (Configuration Packages, package $code, Show Error)."
        # The test app publishes the errors as a read-only API (PBA Config Errors API).
        try {
            (Invoke-RestMethod "$api/contoso/projectBillingDev/v1.0/companies($companyId)/configPackageErrors?`$filter=packageCode eq '$code'" -Headers (Get-AuthHeader)).value |
                Format-Table tableId, recordNumber, fieldId, errorText -AutoSize | Out-String -Width 300 | Write-Host
        } catch { }
    }
}
