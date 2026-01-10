param([Parameter(Mandatory=$false)][string]$IISExpressWorkspaceConfigDirectory=$env:IIS_EXPRESS_WORKSPACE_CONFIG_DIRECTORY,
      [Parameter(Mandatory=$false)][string]$IISExpressDirectory
    )

Push-Location $PSScriptRoot

. .\IISExpressSharedTasksAndConfigs.ps1

if ([string]::IsNullOrEmpty($IISExpressDirectory) -or [string]::IsNullOrWhiteSpace($IISExpressDirectory))
{
    $IISExpressDirectory = $Script:IISExpressDirectory
}

Write-Host "IIS Express Directory: $($IISExpressDirectory)" -ForegroundColor Cyan
Write-Host "Project Config Directory: $($IISExpressWorkspaceConfigDirectory)" -ForegroundColor Cyan

$exitCode = 0
try
{
    Script:Ping-IISExpressAppCmd -IISExpressAppCmdPath $IISExpressAppCmdPath

    if (-not(Test-Path -LiteralPath $IISExpressWorkspaceConfigDirectory -PathType Container))
    {
        Write-Host "Creating a new directory @ $($IISExpressWorkspaceConfigDirectory)" -ForegroundColor Yellow
        New-Item -LiteralPath $IISExpressWorkspaceConfigDirectory -PathType Directory
        Write-Host "Creating new directory completed" -ForegroundColor Green         
    }

    $Script:IISExpressConfigFiles.ForEach{
        if (-not(Test-Path -LiteralPath $($IISExpressWorkspaceConfigDirectory + '\' + $_) -PathType Leaf))
        {
            Write-Host "Copying $($_)" -ForegroundColor Yellow
            Copy-Item -Path $($IISExpressDirectory + '\' + $_) -Destination $IISExpressWorkspaceConfigDirectory
            Write-Host "Copying config $($_) file completed." -ForegroundColor Green
        }
        else
        {
            Write-Warning "Config $($_) Already Exists"
        }
    }
}
catch {
    $exitCode = 1
    Write-Error $_
}
finally
{
    Pop-Location
    exit $exitCode
}