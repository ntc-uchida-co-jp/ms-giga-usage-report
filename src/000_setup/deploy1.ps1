<#
    .SYNOPSIS
        GitHub Actionsを用いたM365テナントデータ取得のための環境構築: 1

    .DESCRIPTION
        GitHub Actionsを用いたM365テナントデータ取得のための環境構築①
        必要なモジュールのインストール

    .EXAMPLE
        PS> deploy1.ps1
#>

$date = (Get-Date).ToString("yyyyMMdd")
$logFolder = ".\log"
$logFile = "$logFolder\$date`_log.txt"
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
    Write-Log -Message "Loading the JSON file and converting it to an object."
    
    $outputs = Get-Content -Path $outputsFilePath | ConvertFrom-Json
    $runningScript = "01_Install-Module\Install-Module.ps1"
    if($outputs.deployProgress."01" -ne "completed") {
        Write-Log -Message "Starting module installation."
        .\01_Install-Module\Install-Module.ps1
    }
    Write-Log -Message "deploy1.ps1 is complete."
    Write-Log -Message "---------------------------------------------"
}
catch{
    Write-Log -Message "An error has occurred while running $runningScript." -Level "Error"
    Write-Log -Message "Please retry exec.bat." -Level "Error"
    Write-Log -Message "---------------------------------------------"
}
