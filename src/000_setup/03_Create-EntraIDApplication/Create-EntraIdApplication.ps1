<#
    .SYNOPSIS
        作業者のGitHub上の構築先リポジトリに対してアクセス権を付与するためのEntra ID アプリケーション作成

    .DESCRIPTION
        作業者のGitHub上の構築先リポジトリに対してアクセス権を付与するためのEntra ID アプリケーション作成

    .PARAMETER githubOrganizationName
        [必須] 作業者のGitHub上の構築先組織名

    .PARAMETER githubRepositoryName
        [必須] 作業者のGitHub上の構築先プライベートリポジトリ名

    .EXAMPLE
        PS> Create-EntraIdApplication.ps1 -githubOrganizationName "your-organization-name" -githubRepositoryName "your-repository-name"
#>

Param(
    [Parameter(Mandatory=$true)]
    [String]$githubOrganizationName,

    [Parameter(Mandatory=$true)]
    [String]$githubRepositoryName
)

$date = (Get-Date).ToString("yyyyMMdd")
$logFolder = ".\log"
$logFile = "$logFolder\$date`_log.txt"
$outputs = Get-Content -Path ".\outputs.json" | ConvertFrom-Json

if (!(Test-Path -Path $logFolder)) {
    New-Item -ItemType Directory -Path $logFolder | Out-Null
}

function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("Info", "Warning", "Error")]
        [string]$Level = "Info"
    )
        
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    switch ($Level) {
        "Info" {
            Write-Host "[INFO] $Message" -ForegroundColor White
            $logMessage = "$timestamp - [INFO] $Message"
        }
        "Warning" {
            Write-Host "[WARNING] $Message" -ForegroundColor Yellow
            $logMessage = "$timestamp - [WARNING] $Message"
        }
        "Error" {
            Write-Host "[ERROR] $Message" -ForegroundColor Red
            $logMessage = "$timestamp - [ERROR] $Message"
        }
    }
    $logMessage | Out-File -FilePath $logFile -Append
}

try{
    $displayName = "MsDeviceUsageReport-App"

    $appExists = az ad app list --filter "displayName eq '$displayName'" | ConvertFrom-Json

    if ($appExists.Count -eq 0) {
        Write-Log -Message "No existing application found with the name '$displayName'. Creating application."
        az ad app create --display-name $displayName
        if ($LASTEXITCODE -ne 0) {
            Write-Log -Message "Failed to create the application."
            throw "Application creation failed."
        } else {
            Write-Log -Message "Application created successfully."
        }
    } else {
        Write-Log -Message "An application with the name '$displayName' already exists. Skipping creation."
    }

    Write-Log -Message "Retrieving the application ID."
    $appId = $(az ad app list --display-name $displayName --query "[].appId" -o tsv)
    $appObjectId = $(az ad app list --display-name $displayName --query "[].id" -o tsv)

    if ([string]::IsNullOrEmpty($appId) -or [string]::IsNullOrEmpty($appObjectId)) {
        throw "Failed to get application ID or Object ID for '$displayName'."
    } else {
        Write-Log -Message "Application ID got successfully: $appId"
        Write-Log -Message "Application Object ID got successfully: $appObjectId"
    }

    Write-Log -Message "Adding Microsoft Graph API permissions."
    Write-Log -Message "Adding permissions for GraphAPI."
    az ad app permission add --id $appId --api 00000003-0000-0000-c000-000000000000 --api-permissions b0afded3-3588-46d8-8b3d-9842eff778da=Role
    az ad app permission add --id $appId --api 00000003-0000-0000-c000-000000000000 --api-permissions 5e1e9171-754d-478c-812c-f1755a9a4c2d=Role
    az ad app permission add --id $appId --api 00000003-0000-0000-c000-000000000000 --api-permissions 7ab1d382-f21e-4acd-a863-ba3e13f7da61=Role
    az ad app permission add --id $appId --api 00000003-0000-0000-c000-000000000000 --api-permissions 230c1aed-a721-4c5d-9cb4-a90514e508ef=Role
    az ad app permission add --id $appId --api 00000003-0000-0000-c000-000000000000 --api-permissions ee353f83-55ef-4b78-82da-555bfa2b4b95=Role
    az ad app permission add --id $appId --api 00000003-0000-0000-c000-000000000000 --api-permissions df021288-bdef-4463-88db-98f22de89214=Role
    az ad app permission add --id $appId --api 00000003-0000-0000-c000-000000000000 --api-permissions 883ea226-0bf2-4a8f-9f9d-92c9162a727d=Role
    Write-Log -Message "Adding permissions for SharePoint."
    az ad app permission add --id $appId --api 00000003-0000-0ff1-ce00-000000000000 --api-permissions 20d37865-089c-4dee-8c41-6967602d4ac8=Role

    Write-Log -Message "Granting admin consent for API permissions."
    az ad app permission admin-consent --id $appId
    Start-Sleep -Seconds 5
    az ad app permission admin-consent --id $appId

    Write-Log -Message "Setting up federated authentication."
    New-AzADAppFederatedCredential -ApplicationObjectId $appObjectId -Audience api://AzureADTokenExchange -Issuer 'https://token.actions.githubusercontent.com' -Name 'GitHub-Actions-Credential' -Subject "repo:$githubOrganizationName/${githubRepositoryName}:ref:refs/heads/main"

    Write-Log -Message "Writing updated data to outputs.json file."
    $outputs.appId = $appId
    $outputs.deployProgress."03" = "completed"
    $outputs | ConvertTo-Json | Set-Content -Path ".\outputs.json"
    
    Write-Log -Message "Execution of Create-EntraIdApplication.ps1 is complete."
    Write-Log -Message "---------------------------------------------"
}
catch{
    $outputs.deployProgress."03" = "failed"
    $outputs | ConvertTo-Json | Set-Content -Path ".\outputs.json"

    Write-Log -Message "An error has occurred: $_" -Level "Error"
    Write-Log -Message "---------------------------------------------"
}
