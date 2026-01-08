param([Parameter(Mandatory=$true)][string]$Path,
      [Parameter(Mandatory=$false)][string]$IISExpressDirectory="C:\Program Files\IIS Express\config\templates\PersonalWebServer"
     )

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
    exit $exitCode
}