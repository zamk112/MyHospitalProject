param([Parameter(Mandatory=$false)][string]$WebsiteName="WebSite1",
      [Parameter(Mandatory=$false)][ValidateScript({if ($_ -is [string] -or $_ -is [string[]]){return true}})]$AppPoolConfig=@('Clr4IntegratedAppPool', 'Clr4ClassicAppPool', 'Clr2IntegratedAppPool', 'Clr2ClassicAppPool', 'UnmanagedClassicAppPool'),
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

Write-Host "Website Name: $($WebsiteName)" -ForegroundColor Cyan
Write-Host "IIS Express Workspace Config Directory: $($IISExpressWorkspaceConfigDirectory)" -ForegroundColor Cyan
Write-Host "IIS Express App CMD Path: $($IISExpressAppCmdPath)" -ForegroundColor Cyan

try
{
    Script:Ping-IISExpressAppCmd -IISExpressAppCmdPath $IISExpressAppCmdPath
    Script:Ping-IISExpressWorkspaceConfigDirectory -IISExpressWorkspaceConfigDirectory $IISExpressWorkspaceConfigDirectory

    Write-Host "Beginning site config deletion for $($WebsiteName) to $($Script:IISExpressConfigFiles[0])" -ForegroundColor Yellow
    $appCmdCommand = "delete site `"$($WebsiteName)`" /apphostconfig:`"$($IISExpressWorkspaceConfigDirectory)\$($Script:IISExpressConfigFiles[0])`""
    $output = Invoke-Expression $(" & '" + $IISExpressAppCmdPath + "' " + $appCmdCommand)

    if ($output -match "^SITE object `"\w+`" deleted$")
    {
        Write-Host $output -ForegroundColor Green
    }
    elseif ($output -match "^ERROR\s?\(\s?message:Cannot find SITE object with identifier `"\w+`"\.\s?\)$") {
        Write-Warning $output
    }
    else {
        throw $output
    }

    Write-Host "Beginning App Pool config deletion" -ForegroundColor Yellow
    if ($AppPoolConfig -is [string])
    {
        $AppPoolConfig = @($AppPoolConfig)
    }

    $AppPoolConfig.ForEach{
        $appCmdCommand = "delete apppool $($_) /apphostconfig:`"$($IISExpressWorkspaceConfigDirectory)\$($Script:IISExpressConfigFiles[0])`""
        $output = Invoke-Expression $(" & '" + $IISExpressAppCmdPath + "' " + $appCmdCommand)

        if ($output -match "^APPPOOL object `"\w+`" deleted$")
        {
            Write-Host $output -ForegroundColor Green
        }
        elseif ($output -match "^ERROR\s?\(\s?message:Cannot find APPPOOL object with identifier `"\w+`"\.\s?\)$") {
            Write-Warning $output
        }
        else {
            throw $output
        }
    }
}
catch {
    $errorCode = 1
    Write-Error $_
}
finally
{
    Pop-Location
    exit $errorCode
}