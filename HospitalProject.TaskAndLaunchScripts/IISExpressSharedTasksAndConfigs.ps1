$Script:IISExpressDirectory = "C:\Program Files\IIS Express\config\templates\PersonalWebServer"
$Script:IISExpressConfigFiles = @('applicationhost.config', 'aspnet.config', 'redirection.config')
$Script:IISExpressAppCmdPath = 'C:\Program Files\IIS Express\appcmd.exe'

function Script:Ping-IISExpressAppCmd
{
    param([Parameter(Mandatory=$true)][string]$IISExpressAppCmdPath)

    if (-not(Test-Path -LiteralPath $IISExpressAppCmdPath -PathType Leaf))
    {
        throw "AppCmd.exe for IIS Express not found"
    }
}

function Script:Ping-IISExpressWorkspaceConfigDirectory
{
    param([Parameter(Mandatory=$true)][string]$IISExpressWorkspaceConfigDirectory)
    
    if (-not(Test-Path -LiteralPath $IISExpressWorkspaceConfigDirectory -PathType Container))
    {
        throw "Config directory does not exist"
    }
}