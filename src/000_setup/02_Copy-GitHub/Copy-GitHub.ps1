<#
    .SYNOPSIS
        マスタリポジトリの内容を作業者のGitHub上の構築先リポジトリにコピー

    .DESCRIPTION
        マスタリポジトリ内のフォルダの内容を作業者のGitHub上の構築先リポジトリにコピー

    .PARAMETER githubOrganizationName
        [必須] 作業者のGitHub上の構築先組織名

    .PARAMETER githubRepositoryName
        [必須] 作業者のGitHub上の構築先プライベートリポジトリ名

    .PARAMETER githubAccountName
        [必須] 作業者のGitHubアカウント名

    .PARAMETER githubAccountMail
        [必須] 作業者のGitHubへの登録メールアドレス

    .EXAMPLE
        PS> Github-Copy.ps1 -githubOrganizationName "your-organization-name" -githubRepositoryName "your-repository-name" -githubAccountName "your-github-account-name"  -githubAccountMail "your-github-account-email"
#>

Param(
    [Parameter(Mandatory=$true)]
    [String]$githubOrganizationName,

    [Parameter(Mandatory=$true)]
    [String]$githubRepositoryName,

    [Parameter(Mandatory=$true)]
    [String]$githubAccountName,

    [Parameter(Mandatory=$true)]
    [String]$githubAccountMail
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
    $returnPath = Get-Location

    Set-Location ../..
    $sourcePath = Resolve-Path -Path "./*"

    Set-Location ..

    Write-Host "Cloning the target GitHub private repository."
    git clone https://github.com/$githubOrganizationName/$githubRepositoryName.git
    Set-Location $githubRepositoryName
    
    Write-Host "Creating a new branch 'copy-dir' and copying all folders from the master repository."

    $branchName = "copy-dir"
    $branchExists = git branch --list $branchName
    if (-not $branchExists) {
        git checkout -b $branchName
        Write-Output "Created and switched to branch '$branchName'"

    } else {
        git checkout $branchName
        Write-Output "Switched to existing branch '$branchName'"
    }

    $destinationPath = (Get-Location).Path

    Write-Host "Copying from '$sourcePath' to '$destinationPath'"

    Copy-Item -Path $sourcePath.Path -Destination $destinationPath -Recurse -Force

    $sourceFolders = Get-Item $sourcePath | Select-Object Name

    ForEach( $folder in $sourceFolders ) {
        $folderName = $folder.Name
        if ( !(Test-Path -Path "$destinationPath\$folderName") ) {
            Write-Error "Failed to copy '$folderName' folder to '$destinationPath'."
            exit 1
        } else {
            Write-Host "'$folderName' folder copied successfully to '$destinationPath'."           
        }
    }
    
    git add .

    git config --global user.name $githubAccountName
    git config --global user.email $githubAccountMail

    git commit -m "Copy folders to private repo"
    
    Write-Host "Pushing changes to the remote repository."
    git push origin copy-dir:main
    
    Set-Location $returnPath
    
    Write-Log -Message "Writing updated data to outputs.json file."
    $outputs.deployProgress."02" = "completed"
    $outputs | ConvertTo-Json | Set-Content -Path ".\outputs.json"
    
    Write-Log -Message "Execution of Copy-Github.ps1 is complete."
    Write-Log -Message "---------------------------------------------"
}
catch{
    $outputs.deployProgress."02" = "failed"
    $outputs | ConvertTo-Json | Set-Content -Path ".\outputs.json"

    Write-Log -Message "An error has occurred: $_" -Level "Error"
    Write-Log -Message "---------------------------------------------"
}
