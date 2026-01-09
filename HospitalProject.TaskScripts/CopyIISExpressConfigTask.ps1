param([Parameter(Mandatory=$false)][string]$Path=$env:WORKSPACE_CONFIG_DIRECTORY,
      [Parameter(Mandatory=$false)][string]$IISExpressDirectory
    )

Push-Location $PSScriptRoot

. .\IISExpressSharedConfig.ps1

if ([string]::IsNullOrEmpty($IISExpressDirectory) -or [string]::IsNullOrWhiteSpace($IISExpressDirectory))
{
    $IISExpressDirectory = $Script:IISExpressDirectory
}

Write-Host "IIS Express Directory: $($IISExpressDirectory)" -ForegroundColor Cyan
Write-Host "Project Config Directory: $($Path)" -ForegroundColor Cyan
$exitCode = 0
try
{
    if (-not(Test-Path -LiteralPath $IISExpressDirectory -PathType Container))
    {
        throw "IIS Express Template Directory does not exist"
    }

    if (-not(Test-Path -LiteralPath $path -PathType Container))
    {
        Write-Host "Creating a new directory @ $($Path)" -ForegroundColor Yellow
        New-Item -LiteralPath $Path -PathType Directory
        Write-Host "Creating new directory completed" -ForegroundColor Green         
    }

    if (-not(Test-Path -LiteralPath $($path + '\applicationhost.config')) -and -not(Test-Path -LiteralPath $($path + '\aspnet.config')) -and -not(Test-Path -LiteralPath $($path + '\redirection.config')))
    {
        Write-Host "Copying applicationhost.config, aspnet.config & redirection config from $($IISExpressDirectory)" -ForegroundColor Yellow
        Copy-Item -Path $($IISExpressDirectory + '\*') -Destination $path -Recurse
        Write-Host "Copying config files completed." -ForegroundColor Green
    }
    else
    {
        Write-Warning "Config Already Exists"
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