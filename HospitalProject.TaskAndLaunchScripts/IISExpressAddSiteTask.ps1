param([Parameter(Mandatory=$true)][string]$AspDotNetCoreSiteName,
      [Parameter(Mandatory=$true)][string]$AspDotNetCoreAppPoolName,
      [Parameter(Mandatory=$true)][string]$AspDotNetCoreURL,
      [Parameter(Mandatory=$true)][string]$AspDotNetCoreAppProtocols,
      [Parameter(Mandatory=$false)][string]$AspDotNetCorePublishBuildPath=$env:ASP_DOT_NET_CORE_PUBLISH_BUILD_PATH,
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

Write-Host "ASP.NET Core Website Name: $($AspDotNetCoreSiteName)" -ForegroundColor Cyan
Write-Host "ASP.NET Core App Pool Name: $($AspDotNetCoreAppPoolName)" -ForegroundColor Cyan
Write-Host "ASP.NET Core URL: $($AspDotNetCoreURL)" -ForegroundColor Cyan
Write-Host "ASP.NET Core App Protocol(s): $($AspDotNetCoreAppProtocols)" -ForegroundColor Cyan
Write-Host "ASP.NET Core Publish Build Path: $($AspDotNetCorePublishBuildPath)" -ForegroundColor Cyan
Write-Host "IIS Express Workspace Config Directory: $($IISExpressWorkspaceConfigDirectory)" -ForegroundColor Cyan
Write-Host "IIS Express App CMD Path: $($IISExpressAppCmdPath)" -ForegroundColor Cyan

try {
    Script:Ping-IISExpressAppCmd -IISExpressAppCmdPath $IISExpressAppCmdPath
    Script:Ping-IISExpressWorkspaceConfigDirectory -IISExpressWorkspaceConfigDirectory $IISExpressWorkspaceConfigDirectory

    if (-not(Test-Path -LiteralPath $AspDotNetCorePublishBuildPath -PathType Container))
    {
        throw "ASP.NET Core Publish Build Path is invalid."
    }

    Write-Host "Adding SITE Config to $($Script:IISExpressConfigFiles[0])" -ForegroundColor Yellow
    $appCmdCommand = "add site /name:`"$($AspDotNetCoreSiteName)`" /applicationDefaults.enabledProtocols:$($AspDotNetCoreAppProtocols) /bindings:`"$($AspDotNetCoreURL)`" /physicalPath:`"$($AspDotNetCorePublishBuildPath)`" /applicationDefaults.applicationPool:`"$($AspDotNetCoreAppPoolName)`" /apphostconfig:`"$($IISExpressWorkspaceConfigDirectory)\$($Script:IISExpressConfigFiles[0])`""
    $output = Invoke-Expression $("& '" + $IISExpressAppCmdPath + "' " + $appCmdCommand)

    $successfulMatchPatterns = @("^SITE object `"[\w+\.]+`" added$", "^APP object `"[\w+\.\/]+`" added$", "^VDIR object `"[\w+\.\/]+`" added$")

    if ($output -is [System.Object[]] -or $output -is [System.Array] -or $output -is [string[]])
    {
        if ($($output -join "") -match "^ERROR \( message:Can not set attribute `"\w+`" to value `"\w*`"\.\. Reason: Invalid site name(?:\s*\. \))?$"){
            throw $($output -join "")
        }
        else {
            $output.ForEach{
                $successMatch = $false
                foreach ($successPatten in $successfulMatchPatterns)
                {
                    if ($_ -match $successPatten)
                    {
                        Write-Host $_ -ForegroundColor Green
                        $successMatch = $true
                        break
                    }
                }

                if ($successMatch -eq $false)
                {
                    Write-Warning $_
                }
            }
        }
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