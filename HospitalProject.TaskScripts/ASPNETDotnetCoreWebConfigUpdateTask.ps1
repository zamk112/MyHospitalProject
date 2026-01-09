param([Parameter(Mandatory=$false)][string]$AspDotnetCoreWebConfigFilePath=$env:ASP_DOTNET_CORE_WEB_CONFIG_FILE_PATH)

$exitCode = 0

Write-Host $AspDotnetCoreWebConfigFilePath -ForegroundColor Cyan

try
{
    if (Test-Path -LiteralPath $AspDotnetCoreWebConfigFilePath -PathType Leaf)
    {
        Write-Host "Updating web.config" -ForegroundColor Yellow
        [xml]$xmlContent = Get-Content -LiteralPath $AspDotnetCoreWebConfigFilePath
        $xmlContent.configuration.location."system.webServer".aspNetCore.stdoutLogEnabled = "true"
        $xmlContent.Save($AspDotnetCoreWebConfigFilePath)
        Write-Host "web.config updated" -ForegroundColor Green

    }
    else
    {
        throw "web.config file does not exist"
    }
}
catch
{
    $exitCode = 1
    Write-Error $_
}
finally
{
    exit $exitCode
}