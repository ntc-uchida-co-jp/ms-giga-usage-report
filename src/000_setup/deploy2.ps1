<#
    .SYNOPSIS
        GitHub Actionsを用いたM365テナントデータ取得のための環境構築: 2

    .DESCRIPTION
        GitHub Actionsを用いたM365テナントデータ取得のための環境構築②
        「params.json」の値に従って環境構築を行うため、事前に設定しておく

    .EXAMPLE
        PS> deploy2.ps1
#>

$date = (Get-Date).ToString("yyyyMMdd")
$logFolder = ".\log"
$logFile = "$logFolder\$date`_log.txt"
$paramsFilePath = ".\params.json"
$outputsFilePath = ".\outputs.json"
$runningScript = ""


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

if (!(Test-Path -Path $logFolder)) {
    New-Item -ItemType Directory -Path $logFolder | Out-Null
}

try{
    $outputs = Get-Content -Path $outputsFilePath | ConvertFrom-Json
    Write-Log -Message "Loading the JSON file and converting it to an object."
    $params = Get-Content -Path $paramsFilePath | ConvertFrom-Json

    Write-Log -Message "Logging into GitHub account."
    Write-Host "Please follow the instructions to log in."
    gh auth login --web --git-protocol https

    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "GitHub CLI login failed with exit code $exitCode"
    }
    else {
        Write-Log -Message "GitHub CLI login succeeded."
    }

    if($outputs.deployProgress."03" -ne "completed" -or $outputs.deployProgress."04" -ne "completed" -or $outputs.deployProgress."05" -ne "completed"){
        Write-Log -Message "Logging into Azure CLI."
        az login --allow-no-subscriptions

        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) {
            throw "Azure CLI login failed with exit code $exitCode"
        } else {
            Write-Log -Message "Azure CLI login succeeded."
        }
    }

    if($outputs.deployProgress."03" -ne "completed" -or $outputs.deployProgress."05" -ne "completed"){
        Write-Log -Message "Logging into Azure account."
        try {
            Connect-AzAccount
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to connect to Azure account."
            }
            Write-Log -Message "Connected to Azure account successfully."
        } 
        catch {
            throw "Azure account connection failed. : $_"
        }
    }

    if($outputs.deployProgress."04" -ne "completed" -or $outputs.deployProgress."05" -ne "completed"){
        Write-Log -Message "Connecting to Microsoft Graph."
        try {
            Connect-MgGraph -Scopes "Group.ReadWrite.All", "User.Read", "Application.ReadWrite.All", "Sites.Read.All", "Sites.FullControl.All"
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to connect to Microsoft Graph."
            }
            Write-Log -Message "Connected to Microsoft Graph successfully."
        } 
        catch {
            throw "Microsoft Graph connection failed. : $_"
        }
    }

    $runningScript = "02_Copy-GitHub\Copy-GitHub.ps1"
    if($outputs.deployProgress."02" -ne "completed") {
        Write-Log -Message "Forking GitHub repository."
        .\02_Copy-GitHub\Copy-GitHub.ps1 -githubOrganizationName $params.githubOrganizationName -githubRepositoryName $params.githubRepositoryName -githubAccountName $params.githubAccountName -githubAccountMail $params.githubAccountMail
    }

    $runningScript = "03_Create-EntraIDApplication\Create-EntraIdApplication.ps1"
    if($outputs.deployProgress."03" -ne "completed") {
        Write-Log -Message "Creating Entra ID application."
        .\03_Create-EntraIDApplication\Create-EntraIdApplication.ps1 -githubOrganizationName $params.githubOrganizationName -githubRepositoryName $params.githubRepositoryName
    }
    
    $runningScript = "04_Create-EntraIDGroup\Create-EntraIdGroup.ps1"
    if($outputs.deployProgress."04" -ne "completed") {
        Write-Log -Message "Creating Entra ID group."
        .\04_Create-EntraIDGroup\Create-EntraIdGroup.ps1
    }
    
    $outputs = Get-Content -Path $outputsFilePath | ConvertFrom-Json
    
    $runningScript = "05_Create-SharePointSite\Create-SharepointSite.ps1"
    if($outputs.deployProgress."02" -eq "completed" -and $outputs.deployProgress."03" -eq "completed" -and $outputs.deployProgress."04" -eq "completed" -and $outputs.deployProgress."05" -ne "completed") {
        Write-Log -Message "Creating SharePoint site."
        .\05_Create-SharePointSite\Create-SharepointSite.ps1 -applicationId $outputs.appId -securityGroupObjectId $outputs.securityGroupObjectId
    }

    $outputs = Get-Content -Path $outputsFilePath | ConvertFrom-Json

    $runningScript = "06_Exec-GitHubActions\Exec-GitHubActions.ps1"
    if($outputs.deployProgress."05" -eq "completed") {
        Write-Log -Message "Adding GitHub secret and executing GitHub Actions workflows."
        .\06_Exec-GitHubActions\Exec-GitHubActions.ps1 -tenantId $outputs.tenantId -tenantDomain $outputs.tenantDomain -applicationId $outputs.appId -githubOrganizationName $params.githubOrganizationName -githubRepositoryName $params.githubRepositoryName
    }

    Write-Log -Message "Deployment is complete."
}
catch{
    Write-Log -Message "An error has occurred while running $runningScript." -Level "Error"
    Write-Log -Message "Please retry deploy2.ps1 script." -Level "Error"
}
finally {
    Write-Log -Message "Logging out from GitHub."
    gh auth logout

    Write-Log -Message "Logging out from Azure CLI."
    az logout

    Write-Log -Message "Logging out from Azure account."
    Disconnect-AzAccount

    Write-Log -Message "Logging out from Microsoft Graph."
    Disconnect-MgGraph
    
    Write-Log -Message "---------------------------------------------"
}
