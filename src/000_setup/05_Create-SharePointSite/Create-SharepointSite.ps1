<#
    .SYNOPSIS
        SharePointサイトの作成

    .DESCRIPTION
        M365テナントデータを蓄積するためのSharePointサイトの作成
        及び、Entra ID アプリケーションへの権限付与

    .PARAMETER applicationId
        [必須] Entra ID アプリケーションID

    .PARAMETER securityGroupObjectId
        [必須] SharePointサイトに対してアクセス権を付与するためのEntra ID セキュリティグループのObject ID

    .EXAMPLE
        PS> Create-SharepointSite.ps1 -applicationId "your-application-id" -securityGroupObjectId "your-security-group-object-id"
#>

Param(
    [Parameter(Mandatory=$true)]
    [String]$applicationId,

    [Parameter(Mandatory=$true)]
    [String]$securityGroupObjectId
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

try {
    Write-Log -Message "Get information of the currently signed-in user."

    $userMail = az ad signed-in-user show --query userPrincipalName --output tsv
    if ([string]::IsNullOrEmpty($userMail)) {
        Write-Log -Message "Failed to get signed-in user's email address."
        throw "Failed to get signed-in user information"
    } else {
        Write-Log -Message "Signed-in user email got successfully: $userMail"
    }

    $tenantInfo = Get-AzTenant
    if (-not $tenantInfo) {
        Write-Log -Message "Failed to get tenant information."
        throw "Failed to get Tenant information"
    } else {
        Write-Log -Message "Tenant information got successfully."
    }

    Write-Log -Message "Get tenant information."
    $fullDomain = $tenantInfo.Domains[0]
    $tenantId = $tenantInfo.Id
    $domainParts = $fullDomain -split '\.'
    $tenantDomain = $domainParts[0]

    Write-Log -Message "Defining SharePoint site settings."
    $siteName = "M365UsageRecords"
    $siteUrl = "https://$tenantDomain.sharepoint.com/sites/$siteName"
    $adminUrl = "https://$tenantDomain-admin.sharepoint.com"
    $template = "STS#3"
    $localeId = 1041
    $storageQuota = 1024

    

    Write-Log -Message "Connecting to SharePoint Online Management Shell."

    Import-Module Microsoft.Online.SharePoint.PowerShell -DisableNameChecking

    Connect-SPOService -Url $adminUrl
    if ($LASTEXITCODE -ne 0) {
        Write-Log -Message "Failed to connect to SharePoint Online Management Shell."
        throw "SharePoint Online Management Shell connection failed."
    } else {
        Write-Log -Message "Connected to SharePoint Online Management Shell successfully."
    }

    Write-Log -Message "Checking if the SharePoint site already exists."
    try {
        Get-SPOSite -Identity $siteUrl -ErrorAction SilentlyContinue
        Write-Log -Message "SharePoint site already exists. No action taken."
    }
    catch {
        Write-Log -Message "No existing SharePoint site found. Creating a new site."
        New-SPOSite -Url $siteUrl -Owner $userMail -StorageQuota $storageQuota -Template $template -LocaleId $localeId -Title $siteName
        if ($LASTEXITCODE -ne 0) {
            Write-Log -Message "Failed to create SharePoint site."
            throw "SharePoint site creation failed."
        } else {
            Write-Log -Message "SharePoint site created successfully."
        }
    }

    Write-Log -Message "Creating LoginName for the security group."
    $securityGroupLoginName = "c:0t.c|tenant|$securityGroupObjectId"

    Write-Log -Message "Adding the security group as a site collection administrator."
    $groupName = "Access Permission Group for M365 Usage Report"

    $group = Get-SPOSiteGroup -Site $siteUrl | Where-Object { $_.Title -eq $groupName }

    if ($null -eq $group) {
    New-SPOSiteGroup -Site $siteUrl -Group $groupName -PermissionLevels "フル コントロール"
    }

    Add-SPOUser -Site $siteUrl -LoginName $securityGroupLoginName -Group $groupName

    Write-Log -Message "Creating a service principal."
    New-MgServicePrincipal -AppId $applicationId -ErrorAction SilentlyContinue

    Write-Log -Message "Getting the service principal."
    $servicePrincipal = Get-MgServicePrincipal -Filter "AppId eq '$applicationId'"

    Write-Log -Message "Service Principal ID: $($servicePrincipal.Id)"

    Write-Log -Message "Getting site information."
    $siteInfo = Get-MgSite -SiteId "$tenantDomain.sharepoint.com:/sites/$siteName"
    if (-not $siteInfo) {
        Write-Log -Message "Failed to retrieve site information for '$siteName'."
        throw "Site information retrieval failed."
    } else {
        Write-Log -Message "Site information retrieved successfully for '$siteName'."
    }
    $siteId = $siteInfo.Id

    Write-Log -Message "Site ID: $siteId"

    $params = @{
        roles = @("write")
        grantedToIdentities = @(
            @{
                application = @{
                    id = $applicationId
                    displayName = $servicePrincipal.DisplayName
                }
            }
        )
    }

    Write-Log -Message "Granting the application permissions to the site."
    New-MgSitePermission -SiteId $siteId -BodyParameter $params

    Write-Log -Message "Writing updated data to outputs.json file."
    $outputs.tenantId = $tenantId
    $outputs.tenantDomain = $tenantDomain
    $outputs.siteUrl = $siteUrl
    $outputs.deployProgress."05" = "completed"
    $outputs | ConvertTo-Json | Set-Content -Path ".\outputs.json"
    
    Write-Log -Message "Execution of Create-SharepointSite.ps1 is complete."
}
catch{
    $outputs.deployProgress."05" = "failed"
    $outputs | ConvertTo-Json | Set-Content -Path ".\outputs.json"

    Write-Log -Message "An error has occurred: $_" -Level "Error"
}
finally{
    Write-Log -Message "Logging out from SharePoint Online Management Shell."
    Disconnect-SPOService

    Write-Log -Message "---------------------------------------------"
}