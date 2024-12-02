<#
    .SYNOPSIS
        必要なモジュールのインストールを行う

    .DESCRIPTION
        利用するモジュールと用途は以下の通り
        ・SharePoint Online管理シェル
            用途：SharePointサイト作成など
        ・Microsoft Graph
            用途：テナント情報取得、Entra IDグループの作成など
        ・Az
            用途：Entra IDアプリケーション作成、権限付与など
        ・Microsoft.Graph.Sites
            用途：Entra IDアプリケーションに対してSharePoint Onlineサイトへの権限付与など

    .EXAMPLE
        PS> Install-Module.ps1
#>

$date = (Get-Date).ToString("yyyyMMdd")
$logFolder = ".\log"
$logFile = $logFolder + "\" + "${date}_log.txt"
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
                $logMessage = "[INFO] $Message"
                Write-Host "$timestamp - $logMessage" -ForegroundColor White
            }
            "Warning" {
                $logMessage = "[WARNING] $Message"
                Write-Host "$timestamp - $logMessage" -ForegroundColor Yellow
        }
        "Error" {
            $logMessage = "[ERROR] $Message"
            Write-Host "$timestamp - $logMessage" -ForegroundColor Red
        }
    }
    $logMessage | Out-File -FilePath $logFile -Append
}

try{
    Write-Log -Message "Starting the installation of required modules..."
    
    $RequiredModules = 'Microsoft.Online.SharePoint.PowerShell', 'Az', 'Microsoft.Graph', 'Microsoft.Graph.Sites'
    ForEach( $Module in $RequiredModules ) {
        If ( !(Get-Module -ListAvailable -Name $Module) ) {
            Write-Log -Message "Installing $Module..."
            Install-Module -Name $Module -Scope CurrentUser -Force -AllowClobber
            Write-Log -Message "$Module installation completed."
        }
    }

    Write-Log -Message "Writing updated data to outputs.json file."
    $outputs.deployProgress."01" = "completed"
    $outputs | ConvertTo-Json | Set-Content -Path ".\outputs.json"
    
    Write-Log -Message "Execution of Install-Module.ps1 is complete."
    Write-Log -Message "---------------------------------------------"
}
catch{
    $outputs.deployProgress."01" = "failed"
    $outputs | ConvertTo-Json | Set-Content -Path ".\outputs.json"

    Write-Log -Message "An error has occurred: $_" -Level "Error"
    Write-Log -Message "---------------------------------------------"
}