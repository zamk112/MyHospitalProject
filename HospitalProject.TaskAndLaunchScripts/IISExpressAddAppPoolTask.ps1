param([Parameter(Mandatory=$true)][string]$AspDotNetCoreAppPoolName,
      [Parameter(Mandatory=$false)][string]$AppPoolManagedRunTimeVersion=$env:ASP_DOT_NET_APP_POOL_RUN_TIME_VERSION,
      [Parameter(Mandatory=$false)][string]$AppPoolManagedPipeLineMode=$env:ASP_DOT_NET_APP_POOL_PIPELINE_MODE,
      [Parameter(Mandatory=$false)][string]$IISExpressWorkspaceConfigDirectory=$env:IIS_EXPRESS_WORKSPACE_CONFIG_DIRECTORY,
      [Parameter(Mandatory=$false)][string]$IISExpressAppCmdPath
     )

Push-Location $PSScriptRoot

. .\IISExpressSharedTasksAndConfigs.ps1

$errorCode = 0

if ([string]::IsNullOrWhiteSpace($IISExpressAppCmdPath) -or [string]::IsNullOrEmpty($IISExpressAppCmdPath))
{
    $IISExpressAppCmdPath = $Script:IISExpressAppCmdPath
}

Write-Host "IIS Express App Pool Config:`n App Pool Name: $($AspDotNetCoreAppPoolName) `nApp Pool Managed Runtime Version: $($AppPoolManagedRunTimeVersion) `nApp Pool Pipeline Mode: $($AppPoolManagedPipeLineMode)" -ForegroundColor Cyan
Write-Host "IIS Express Workspace Config Directory: $($IISExpressWorkspaceConfigDirectory)" -ForegroundColor Cyan
Write-Host "IIS Express App CMD Path: $($IISExpressAppCmdPath)" -ForegroundColor Cyan

try {

    Script:Ping-IISExpressAppCmd -IISExpressAppCmdPath $IISExpressAppCmdPath
    Script:Ping-IISExpressWorkspaceConfigDirectory -IISExpressWorkspaceConfigDirectory $IISExpressWorkspaceConfigDirectory

    Write-Host "Beginning adding App Pool config $($AspDotNetCoreAppPoolName) to $($Script:IISExpressConfigFiles[0])" -ForegroundColor Yellow
    $appCmdCommand = "add apppool /name:`"$($AspDotNetCoreAppPoolName)`" /managedRuntimeVersion:`"$($AppPoolManagedRunTimeVersion)`" /managedPipelineMode:`"$($AppPoolManagedPipeLineMode)`" /apphostconfig:`"$($IISExpressWorkspaceConfigDirectory)\$($Script:IISExpressConfigFiles[0])`""
    $output = Invoke-Expression $("& '" + $IISExpressAppCmdPath + "' " + $appCmdCommand)

    if ($output -match "^APPPOOL object `"\w+`" added$")
    {
        Write-Host $output -ForegroundColor Green
    }
    elseif ($output -match "^ERROR\s?\(\s?message:Failed to add duplicate collection element `"AspDotNetCoreAppPool`"\.\s?\)$") {
        Write-Warning $output
    }
    else {
        throw $output
    }
}
catch {
    $errorCode = 1
    Write-Error $_
}
finally {
    Pop-Location
    exit $errorCode
}