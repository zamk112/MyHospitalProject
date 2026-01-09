param([Parameter(Mandatory=$false)][string]$AspDotnetPublishPath=$env:ASP_DOTNET_CORE_PUBLISH_PATH)

$exitCode = 0

Write-Host $AspDotnetPublishPath -ForegroundColor Cyan

try {
    if (Test-Path -LiteralPath $AspDotnetPublishPath -PathType Container)
    {
        $logsDirectoryPath = $($AspDotnetPublishPath + "/logs")
        if (-not(Test-Path -LiteralPath $logsDirectoryPath -PathType Container))
        {
            Write-Host "Creating logs directory: $($logsDirectoryPath)" -ForegroundColor Yellow
            New-Item -Path $logsDirectoryPath -ItemType Directory
            Write-Host "$($logsDirectoryPath) created." -ForegroundColor Green
        }
        else 
        {
            Write-Warning "Logs Directory $($logsDirectoryPath) already exists"
        }
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