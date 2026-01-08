# Introduction
At my previous job, since I was in **GO-GO-GO** mode, one thing that slowed me down was the IIS Setup and I was not able to setup a reverse proxy in IIS from my frontend to backend. This is why I want to utilise IIS Express, so I can get closer to deployment to IIS and it's a step for fine tuning things, at least for ASP.NET Core because with IIS Express:  
* The configuration will be pretty close to IIS.
* I can still easily debug while it is running on IIS Express from VS Code. This will come in handy for later as well. 

But for the ReactJS frontend, I need to deploy it on IIS, because I need ARR not only for the URL Rewrite but also for the reverse proxying functionality, which IIS Express does not have. And it's going to get more complicated when I start creating certificates that are not of the same domain. 

Before I get started for doing some deployments and running my web application stack. I want to give a quick run through of IIS Express. 

# IIS Express Run Down
## Installation
There's two ways to install IIS Express. The first way is to download the MSI from the [Microsoft Website](https://www.microsoft.com/en-us/download/details.aspx?id=48264) or from installing Visual Studio and selecting the ASP.NET and web development option from the Visual Studio Installer.  
![Installing ASP.NET and web development option from Visual Studio Installer](./images/Screenshot%202026-01-03%20at%205.31.11 pm.png)

When you create a React TypeScript and ASP.NET Core Web API project, you have the option to run your ASP.NET Core Web Api application from IIS Express.  
![Using IIS Express for hosting ASP.NET Core WebAPI](./images/Screenshot%202026-01-03%20at%205.36.14 pm.png)

Not exactly, how I want to use it because I want IIS Express to host both my frontend and backend at the same time. And the second thing you need to install is the [ASP.NET Core Module/Hosting Bundle](https://learn.microsoft.com/en-us/aspnet/core/host-and-deploy/iis/?view=aspnetcore-10.0). This is needed for both IIS and IIS Express. 

Before I go on with the deployments and setup, I just want to discuss or show you how you can run IIS Express without Visual Studio. 

## Running IIS Express without Visual Studio
You can launch **C:\Program Files\IIS Express\iisexpress.exe** from command line.  
```pwsh
> & 'C:\Program Files\IIS Express\iisexpress.exe'
C:\Users\zamk1>"C:\Program Files\IIS Express\iisexpress.exe"
Starting IIS Express ...
Successfully registered URL "http://localhost:8080/" for site "WebSite1" application "/"
Registration completed for site "WebSite1"
IIS Express is running.
Enter 'Q' to stop IIS Express
```

As you can see, it launched *Website1* with the URL of *http://localhost:8080/*. And yes you can go to this URL.  
![IIS Express Web page](./images/Screenshot%202026-01-03%20at%205.54.38 pm.png)

But where is *Website1* stored? It's in **\Documents\My Web Sites** directory.  
```cmd
C:\Users\zamk1\Documents\My Web Sites\WebSite1>dir
 Volume in drive C has no label.
 Volume Serial Number is AE69-A758

 Directory of C:\Users\zamk1\Documents\My Web Sites\WebSite1

22/12/2025  03:02 AM    <DIR>          .
22/12/2025  03:02 AM    <DIR>          ..
07/02/2025  01:15 AM           289,940 bkg-blu.jpg
07/02/2025  01:15 AM            98,757 iis.png
07/02/2025  01:15 AM               691 iisstart.htm
07/02/2025  01:15 AM             2,698 msweb-brand.png
07/02/2025  01:15 AM            10,165 w-brand.png
               5 File(s)        402,251 bytes
               2 Dir(s)  142,310,400,000 bytes free
```

And IIS Express configs are also in **Documents** directory as well.  
```cmd
C:\Users\zamk1\Documents\IISExpress>dir
 Volume in drive C has no label.
 Volume Serial Number is AE69-A758

 Directory of C:\Users\zamk1\Documents\IISExpress

22/12/2025  03:02 AM    <DIR>          .
22/12/2025  03:16 AM    <DIR>          ..
22/12/2025  03:02 AM    <DIR>          config
22/12/2025  03:02 AM    <DIR>          Logs
22/12/2025  03:02 AM    <DIR>          TraceLogFiles
               0 File(s)              0 bytes
               5 Dir(s)  142,272,372,736 bytes free

C:\Users\zamk1\Documents\IISExpress>cd config

C:\Users\zamk1\Documents\IISExpress\config>dir
 Volume in drive C has no label.
 Volume Serial Number is AE69-A758

 Directory of C:\Users\zamk1\Documents\IISExpress\config

22/12/2025  03:02 AM    <DIR>          .
22/12/2025  03:02 AM    <DIR>          ..
07/02/2025  01:15 AM            83,168 applicationhost.config
07/02/2025  01:15 AM             1,279 aspnet.config
08/12/2023  03:41 AM               509 redirection.config
               3 File(s)         84,956 bytes
               2 Dir(s)  142,272,372,736 bytes free
```
When IIS Expressing is running, you should see it in the task bar and see what web applications are running by right-clicking on the icon and then click on *Show All Applications*.  
![IIS Express running in task bar and showing which web app is running](./images/Screenshot%202026-01-03%20at%206.05.19 pm.png)

IIS Express is sort a cut down version of IIS without the GUI but you can use command line prompts to configure it like you would with IIS.

# Debug Release build for ASP.NET Core project
Before I start configuring IIS Express, I need to do *publish* a debug build. Technically, you don't have to do this but you need to create the **web.config** and put in your **\HospitalProject.Server\bin\Debug\net10.0** directory. But I did just in case I want to mess around with my config for my local and IIS Express development setups. My goal at least..... is not to break stuff 😅. And I do it with this PowerShell command:  
```pwsh
"cd HospitalProject.Server && dotnet publish -c Debug" | cmd
```

And you should get an output like this:  
```pwsh
PS > . $args[0] "cd HospitalProject.Server && dotnet publish -c Debug" | cmd
Microsoft Windows [Version 10.0.26200.7462]
(c) Microsoft Corporation. All rights reserved.

Z:\Projects\MyHospitalProject>cd HospitalProject.Server && dotnet publish -c Debug
Restore complete (0.5s)
  HospitalProject.Server net10.0 succeeded (0.6s) → bin\Debug\net10.0\publish\

Build succeeded in 1.8s
```

And the second thing I did was updated **web.config** and added the **ASPNET_ENVIRONMENT** environment variable as well as enable the `stdout` logging (for additional logging to see what's happening on IIS Express side).  
```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <location path="." inheritInChildApplications="false">
    <system.webServer>
      <handlers>
        <add name="aspNetCore" path="*" verb="*" modules="AspNetCoreModuleV2" resourceType="Unspecified" />
      </handlers>
      <aspNetCore processPath="dotnet" arguments=".\HospitalProject.Server.dll" stdoutLogEnabled="true" stdoutLogFile=".\logs\stdout" hostingModel="inprocess">
        <environmentVariables>
          <environmentVariable name="ASPNETCORE_ENVIRONMENT" value="Development" />
        </environmentVariables>
      </aspNetCore>
    </system.webServer>
  </location>
</configuration>
<!--ProjectGuid: EACAB167-848F-266E-51FD-C92F8284B348-->
``` 
The environment variable is just for now, later (I'm hoping) I won't need it. And make sure to create your **logs** folder in **HospitalProject.Server\bin\Debug\net10.0\publish** directory as well.

# Setting up the config for IIS express
## Copy and Clean up
The first thing I need to do is copy the config files over. Again doing it with some PowerShell code to the copy.  
```pwsh
try
{
    if (Test-Path -LiteralPath 'C:\Program Files\IIS Express\config\templates\PersonalWebServer' -PathType Container)
    {
        Copy-Item -Path 'C:\Program Files\IIS Express\config\templates\PersonalWebServer\*' -Destination .\HospitalProject.IISConfiguration\IISExpressConfiguration -Recurse
    }
    else {
        throw "Directory does not exist"
    }
}
catch {
    Write-Error $_
}
```

You should get an output like this:
```pwsh
PS > . $args[0] try
{
    if (Test-Path -LiteralPath 'C:\Program Files\IIS Express\config\templates\PersonalWebServer' -PathType Container)
    {
        Copy-Item -Path 'C:\Program Files\IIS Express\config\templates\PersonalWebServer\*' -Destination .\HospitalProject.IISConfiguration\IISExpressConfiguration -Recurse
    }
    else {
        throw "Directory does not exist"
    }
}
catch {
    Write-Error $_
}
```

Next, I need to remove the config for the default site. For this I'm going to **appcmd.exe** not using the one for IIS though. IIS Express has its own one and again going to use PowerShell because I suck at writing bat files 😅 at least with validation.  
```pwsh
try
{
    $IISExpressAppCmdPath = 'C:\Program Files\IIS Express\appcmd.exe'
    $RelativePathToConfig = '.\HospitalProject.IISConfiguration\IISExpressConfiguration'
    $WebsiteName = "WebSite1"

    if (Test-Path -LiteralPath $IISExpressAppCmdPath -PathType Leaf)
    {
        $fullPath = Resolve-Path -Path $RelativePathToConfig
        $appCmdCommand = "delete site `"$($WebsiteName)`" /apphostconfig:`"$($fullPath)\applicationhost.config`""
    
        Invoke-Expression $(" & '" + $IISExpressAppCmdPath + "' " + $appCmdCommand)
    }
}
catch {
    Write-Error $_
}
```
You should see an output like this:  
```pwsh
PS > . $args[0] try
{
    $IISExpressAppCmdPath = 'C:\Program Files\IIS Express\appcmd.exe'
    $RelativePathToConfig = '.\HospitalProject.IISConfiguration\IISExpressConfiguration'
    $WebsiteName = "WebSite1"

    if (Test-Path -LiteralPath $IISExpressAppCmdPath -PathType Leaf)
    {
        $fullPath = Resolve-Path -Path $RelativePathToConfig
        $appCmdCommand = "delete site `"$($WebsiteName)`" /apphostconfig:`"$($fullPath)\applicationhost.config`""

        Invoke-Expression $(" & '" + $IISExpressAppCmdPath + "' " + $appCmdCommand)
    }
}
catch {
    Write-Error $_
}
SITE object "WebSite1" deleted
```

When you create a website on IIS, and deploy your ASP.NET Core application onto it, the application pool configuration is as follows:  
* .NET CLR Version: *No Managed Code*
* Managed pipeline mode: *Integrated*

For that I'm going to delete all the application pools in the **applicationhost.config**, and then add one for ASP.NET Core version which I have mentioned above.  

First things first, I need to delete all the application pools.  
```pwsh
try
{
    $IISExpressAppCmdPath = 'C:\Program Files\IIS Express\appcmd.exe'
    $RelativePathToConfig = '.\HospitalProject.IISConfiguration\IISExpressConfiguration'

    if (Test-Path -LiteralPath $IISExpressAppCmdPath -PathType Leaf)
    {
        $fullPath = Resolve-Path -Path $RelativePathToConfig
        $appCmdListAppPoolCommand = "list apppools /apphostconfig:`"$($fullPath)\applicationhost.config`""
    
        $outStr = Invoke-Expression $("& '" + $IISExpressAppCmdPath + "' " + $appCmdListAppPoolCommand)
        $outStr.ForEach{
            if($_ -match "^APPPOOL `"(\w+)`" .+$")
            {
                $appCmdDeleteAppPoolCommand = "delete apppool $($Matches[1]) /apphostconfig:`"$($fullPath)\applicationhost.config`""
                Invoke-Expression $("& '" + $IISExpressAppCmdPath + "' " + $appCmdDeleteAppPoolCommand)
            }
        }
    }
}
catch {
    Write-Error $_
}
```

You should get an output like this:  
```pwsh
PS > . $args[0] try
{
    $IISExpressAppCmdPath = 'C:\Program Files\IIS Express\appcmd.exe'
    $RelativePathToConfig = '.\HospitalProject.IISConfiguration\IISExpressConfiguration'

    if (Test-Path -LiteralPath $IISExpressAppCmdPath -PathType Leaf)
    {
        $fullPath = Resolve-Path -Path $RelativePathToConfig
        $appCmdListAppPoolCommand = "list apppools /apphostconfig:`"$($fullPath)\applicationhost.config`""

        $outStr = Invoke-Expression $("& '" + $IISExpressAppCmdPath + "' " + $appCmdListAppPoolCommand)
        $outStr.ForEach{
            if($_ -match "^APPPOOL `"(\w+)`" .+$")
            {
                $appCmdDeleteAppPoolCommand = "delete apppool $($Matches[1]) /apphostconfig:`"$($fullPath)\applicationhost.config`""
                Invoke-Expression $("& '" + $IISExpressAppCmdPath + "' " + $appCmdDeleteAppPoolCommand)
            }
        }
    }
}
catch {
    Write-Error $_
}
APPPOOL object "Clr4IntegratedAppPool" deleted
APPPOOL object "Clr4ClassicAppPool" deleted
APPPOOL object "Clr2IntegratedAppPool" deleted
APPPOOL object "Clr2ClassicAppPool" deleted
APPPOOL object "UnmanagedClassicAppPool" deleted
```

I'm going to add a new Application Pool:  
```pwsh
try
{
    $IISExpressAppCmdPath = 'C:\Program Files\IIS Express\appcmd.exe'
    $RelativePathToConfig = '.\HospitalProject.IISConfiguration\IISExpressConfiguration'
    $AspDotNetCoreAppPoolName = 'AspDotNetCoreAppPool'
    $AppPoolManagedRunTimeVersion = ''
    $AppPoolManagedPipeLineMode = 'Integrated'


    if (Test-Path -LiteralPath $IISExpressAppCmdPath -PathType Leaf)
    {
        $fullPath = Resolve-Path -Path $RelativePathToConfig
        $appCmdCommand = "add apppool /name:`"$($AspDotNetCoreAppPoolName)`" /managedRuntimeVersion:`"$($AppPoolManagedRunTimeVersion)`" /managedPipelineMode:`"$($AppPoolManagedPipeLineMode)`" /apphostconfig:`"$($fullPath)\applicationhost.config`""
        Invoke-Expression $("& '" + $IISExpressAppCmdPath + "' " + $appCmdCommand)
    }
}
catch {
    Write-Error $_
}
```

You should get an output like this:  
```pwsh
PS > . $args[0] try
{
    $IISExpressAppCmdPath = 'C:\Program Files\IIS Express\appcmd.exe'
    $RelativePathToConfig = '.\HospitalProject.IISConfiguration\IISExpressConfiguration'
    $AspDotNetCoreAppPoolName = 'AspDotNetCoreAppPool'
    $AppPoolManagedRunTimeVersion = ''
    $AppPoolManagedPipeLineMode = 'Integrated'


    if (Test-Path -LiteralPath $IISExpressAppCmdPath -PathType Leaf)
    {
        $fullPath = Resolve-Path -Path $RelativePathToConfig
        $appCmdCommand = "add apppool /name:`"$($AspDotNetCoreAppPoolName)`" /managedRuntimeVersion:`"$($AppPoolManagedRunTimeVersion)`" /managedPipelineMode:`"$($AppPoolManagedPipeLineMode)`" /apphostconfig:`"$($fullPath)\applicationhost.config`""
        Invoke-Expression $("& '" + $IISExpressAppCmdPath + "' " + $appCmdCommand)
    }
}
catch {
    Write-Error $_
}
APPPOOL object "AspDotNetCoreAppPool" added

This is so just in case you want to add another ASP.NET Core backend endpoint. Lastly, I need to add the website with the following command:  
```pwsh
try
{
    $IISExpressAppCmdPath = 'C:\Program Files\IIS Express\appcmd.exe'
    $RelativePathToConfig = '.\HospitalProject.IISConfiguration\IISExpressConfiguration'
    $AspDotNetCoreAppPoolName = 'AspDotNetCoreAppPool'
    $AspDotNetCoreSiteName = 'HospitalProject.Server.Dev'
    $AspDotNetCoreURL = 'https://localhost:44300'
    $AspDotNetCoreDebugPublishBuild = '.\HospitalProject.Server\bin\Debug\net10.0\publish'
    $AspDotNetCoreAppProtocols = 'https'

    if (Test-Path -LiteralPath $IISExpressAppCmdPath -PathType Leaf)
    {
        $fullPath = Resolve-Path -Path $RelativePathToConfig
        $AspDotNetCoreDebugPublishBuildFullPath = Resolve-Path -Path $AspDotNetCoreDebugPublishBuild
        $appCmdCommand = "add site /name:`"$($AspDotNetCoreSiteName)`" /applicationDefaults.enabledProtocols:$($AspDotNetCoreAppProtocols) /bindings:`"$($AspDotNetCoreURL)`" /physicalPath:`"$($AspDotNetCoreDebugPublishBuildFullPath)`" /applicationDefaults.applicationPool:`"$($AspDotNetCoreAppPoolName)`" /apphostconfig:`"$($fullPath)\applicationhost.config`""
        Invoke-Expression $("& '" + $IISExpressAppCmdPath + "' " + $appCmdCommand)
    }
}
catch {
    Write-Error $_
}
```

You should get an output like this:  
```pwsh
PS > . $args[0] try
{
    $IISExpressAppCmdPath = 'C:\Program Files\IIS Express\appcmd.exe'
    $RelativePathToConfig = '.\HospitalProject.IISConfiguration\IISExpressConfiguration'
    $AspDotNetCoreAppPoolName = 'AspDotNetCoreAppPool'
    $AspDotNetCoreSiteName = 'HospitalProject.Server.Dev'
    $AspDotNetCoreURL = 'https://localhost:44300'
    $AspDotNetCoreDebugPublishBuild = '.\HospitalProject.Server\bin\Debug\net10.0\publish'
    $AspDotNetCoreAppProtocols = 'https'

    if (Test-Path -LiteralPath $IISExpressAppCmdPath -PathType Leaf)
    {
        $fullPath = Resolve-Path -Path $RelativePathToConfig
        $AspDotNetCoreDebugPublishBuildFullPath = Resolve-Path -Path $AspDotNetCoreDebugPublishBuild
        $appCmdCommand = "add site /name:`"$($AspDotNetCoreSiteName)`" /applicationDefaults.enabledProtocols:$($AspDotNetCoreAppProtocols) /bindings:`"$($AspDotNetCoreURL)`" /physicalPath:`"$($AspDotNetCoreDebugPublishBuildFullPath)`" /applicationDefaults.applicationPool:`"$($AspDotNetCoreAppPoolName)`" /apphostconfig:`"$($fullPath)\applicationhost.config`""    
        Invoke-Expression $("& '" + $IISExpressAppCmdPath + "' " + $appCmdCommand)
    }
}
catch {
    Write-Error $_
}
SITE object "HospitalProject.Server.Dev" added
APP object "HospitalProject.Server.Dev/" added
VDIR object "HospitalProject.Server.Dev/" added
```

## Moment of truth, can I launch ASP.NET Core from IIS Express without **launchSettings.json** file?
After running all of these PowerShell commands, the ASP.NET Core Web API endpoint should work right? Let's see what happens after starting up the server with this command:  
```pwsh
& 'C:\Program Files\IIS Express\iisexpress.exe' /site:"HospitalProject.Server.Dev" /config:"Z:\Projects\MyHospitalProject\HospitalProject.IISConfiguration\IISExpressConfiguration\applicationhost.config"
``` 

I'm just running the command from the PowerShell terminal and getting an output like this:  
```pwsh
& 'C:\Program Files\IIS Express\iisexpress.exe' /site:"HospitalProject.Server.Dev" /config:"Z:\Projects\MyHospitalProject\HospitalProject.IISConfiguration\IISExpressConfiguration\applicationhost.config"
Starting IIS Express ...
Successfully registered URL "https://localhost:44300/" for site "HospitalProject.Server.Dev" application "/"
Registration completed for site "HospitalProject.Server.Dev"
IIS Express is running.
Enter 'Q' to stop IIS Express
```

And this is what it looks like on the IIS Express Running Applications window.  
![IIS Express Running Applications window](./images/Screenshot%202026-01-07%20at%208.15.09 pm.png)

Let's do an API call with Bruno and we get "The connection was reset" error that you would see on a browser.  
![Bruno ECONNRESET message](./images/Screenshot%202026-01-07%20at%208.17.45 pm.png)

The reason for this error is I need to bind the certificate to IIS Express, which I will do next.  

## Binding SSL certificate to IIS Express
So when you run `dotnet dev-certs https --trust` or build a ASP.NET Core project in Visual Studio, you'd get the message you get the message saying do you want to install certificates for IIS Express and you click "Yes". When that happens the self-signed certificate is install on the LOCAL Machine profile.  
![Local Machine Personal Certificate folder](./images/Screenshot%202026-01-07%20at%208.33.25 pm.png)

And in your Current User profile under the Trusted Root Certification Authorities -> Certificates folder.  
![Current User Trusted Root Certification Authorities folder](./images/Screenshot%202026-01-07%20at%209.11.10 pm.png)

Whereas the ASP.NET Core HTTPS development certificate both live under the current user profile (Personal & Trusted Root Certification Authorities) and another difference between the two type of certificates are that the IIS Express Development Certificate does have a private key associated to it.

Basically, Trusted Root Certification Authorities contains the public certificate and Personal contains the private certificate (Sorry for the slide rambling). 

Nonetheless, I need to bind the IIS Express Certificate to the IIS Express application. To do this, we need to run the `netsh` command as **Administrator**:  
```pwsh
Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile -NoExit -Command "\"netsh http add sslcert ipport=0.0.0.0:44300 certhash=_THUMBPRINT_HERE_ appid={214124cd-d05b-4309-9af9-9caa44b2b74a}\" | cmd"'
```

I will get a UAC for running as admin and this command will launch another PS window running the shell command and give the following output:  
```pwsh
Microsoft Windows [Version 10.0.26200.7462]
(c) Microsoft Corporation. All rights reserved.

C:\Windows\System32>netsh http add sslcert ipport=0.0.0.0:44300 certhash=_THUMBPRINT_HERE_ appid={214124cd-d05b-4309-9af9-9caa44b2b74a}

SSL Certificate successfully added


C:\Windows\System32>
PS C:\WINDOWS\system32>
```

Now I'm going to launch IIS Express again with the command below:  
```pwsh
& 'C:\Program Files\IIS Express\iisexpress.exe' /site:"HospitalProject.Server.Dev" /config:"Z:\Projects\MyHospitalProject\HospitalProject.IISConfiguration\IISExpressConfiguration\applicationhost.config"
```

Now I'm going  to do an API call with Bruno.  
![Successful API call with Bruno](./images/Screenshot%202026-01-07%20at%2010.14.32 pm.png)

Great, it's working now. And you should see an output like this in your console.  
```pwsh
PS > & 'C:\Program Files\IIS Express\iisexpress.exe' /site:"HospitalProject.Server.Dev" /config:"Z:\Projects\MyHospitalProject\HospitalProject.IISConfiguration\IISExpressConfiguration\applicationhost.config"
Starting IIS Express ...
Successfully registered URL "https://localhost:44300/" for site "HospitalProject.Server.Dev" application "/"
Registration completed for site "HospitalProject.Server.Dev"
IIS Express is running.
Enter 'Q' to stop IIS Express
Request started: "GET" https://localhost:44300/weatherforecast
Response sent: https://localhost:44300/weatherforecast with HTTP status 200.0
Response sent: https://localhost:44300/weatherforecast with HTTP status 200.0
```

## Remote Debugging with VS Code
Fortunately, you can do remote debugging with VS code and of course from Visual Studio you can do remote debugging and you can attach to an IIS or IIS Express process by installing the Remote Tools that you need to work with Visual Studio as per [Remote debug ASP.NET on an IIS computer - Visual Studio (Windows) | Microsoft Learn](https://learn.microsoft.com/en-us/visualstudio/debugger/remote-debugging-aspnet-on-a-remote-iis-7-5-computer?view=visualstudio#BKMK_msvsmon). But on VS code the C# Dev Kit can attached to a dotnet process provided that the dotnet version is greater than dotnet 5. 

First I need to start up my IIS application with:  
```pwsh
& 'C:\Program Files\IIS Express\iisexpress.exe' /site:"HospitalProject.Server.Dev" /config:"Z:\Projects\MyHospitalProject\HospitalProject.IISConfiguration\IISExpressConfiguration\applicationhost.config"
```

Once IIS Express is up and running, I should be able to see **iisexpress.exe** running.  
![iisexpress.exe process running](./images/Screenshot%202026-01-08%20at%208.17.39 pm.png)

I need the *Process ID* (or *PID*) in order for VS code to attach to process. To attach to the process, press `Ctrl+Shift+P` to open the command palette and search for *Debug: Attach to a .NET 5+ or .NET Core process*.  
![Command palette and search for Attach to a .NET Process](./images/Screenshot%202026-01-08%20at%208.21.17 pm.png)

Once you have selected it search for the **iisexpress.exe** process and make sure the *PID* is the same one.  
![Select iisexpress.exe process](./images/Screenshot%202026-01-08%20at%208.24.54 pm.png)

And now, VS code is attached to the process. In ![WeatherForecastController.cs](../HospitalProject.Server/Controllers/WeatherForecastController.cs), I'm also going to set a breakpoint and then do an API call with Bruno. and it should hit the breakpoint.  
![Attach to Process Debug mode](./images/Screenshot%202026-01-08%20at%208.28.39 pm.png)

And great it is working!

## Do IIS Express and Vite play nicely with each other?
I have done all this work, the million dollar question how is will this work with my ReactJS Frontend running on vite? And yes it does!. I'm going temporarily going to update the port number for the ASP.NET Core backend to port 44300 in [vite.config.ts](../HospitalProject.Client/vite.config.ts). And it should start up.  
```ts
...
const target = 'https://localhost:44300';

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    react({
      babel: {
        plugins: [['babel-plugin-react-compiler']],
      },
    }),
  ],
  server: {
    port: 5173,
    https: {
      key: fs.readFileSync(keyPath),
      cert: fs.readFileSync(certPath),
    },
    proxy: {
      '^/weatherforecast': {
        target: target,
        secure: true,
      },      
    },
  },
})

```

Notice, `proxy.secure` value is still `true`. Now I'm going to start up both IIS Express and Vite and the page should just load.  
![React JS page loaded running on Vite but port number changed to IIS Express port](./images/Screenshot%202026-01-08%20at%208.40.28 pm.png)

And the response was captured in the console of where I started the IIS Express application as well.  
```cmd
PS Z:\Projects\MyHospitalProject> & 'C:\Program Files\IIS Express\iisexpress.exe' /site:"HospitalProject.Server.Dev" /config:"Z:\Projects\MyHospitalProject\HospitalProject.IISConfiguration\IISExpressConfiguration\applicationhost.config"
Starting IIS Express ...
Successfully registered URL "https://localhost:44300/" for site "HospitalProject.Server.Dev" application "/"
Registration completed for site "HospitalProject.Server.Dev"
IIS Express is running.
Enter 'Q' to stop IIS Express
Request started: "GET" https://localhost:44300/weatherforecast
Request started: "GET" https://localhost:44300/weatherforecast
2026-01-08 20:40:15 [INF] Application started! Logging stuff now!.
2026-01-08 20:40:15 [INF] Application started. Press Ctrl+C to shut down.
2026-01-08 20:40:15 [INF] Hosting environment: Development
2026-01-08 20:40:15 [INF] Content root path: Z:\Projects\MyHospitalProject\HospitalProject.Server\bin\Debug\net10.0\publish
2026-01-08 20:40:15 [INF] Request starting HTTP/1.1 GET https://localhost:5173/weatherforecast - null null
2026-01-08 20:40:15 [INF] Request starting HTTP/1.1 GET https://localhost:5173/weatherforecast - null null
2026-01-08 20:40:15 [INF] Request:
Protocol: HTTP/1.1
Method: GET
Scheme: https
PathBase:
Path: /weatherforecast
Accept: */*
Accept-Encoding: gzip, deflate, br, zstd
Accept-Language: en-US,en;q=0.9
Connection: close
Host: localhost:5173
Referer: https://localhost:5173/
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36 Edg/143.0.0.0
sec-ch-ua-platform: "Windows"
sec-ch-ua: "Microsoft Edge";v="143", "Chromium";v="143", "Not A(Brand";v="24"
sec-ch-ua-mobile: ?0
sec-fetch-site: same-origin
sec-fetch-mode: cors
sec-fetch-dest: empty
priority: u=1, i
2026-01-08 20:40:15 [INF] Request:
Protocol: HTTP/1.1
Method: GET
Scheme: https
PathBase:
Path: /weatherforecast
Accept: */*
Accept-Encoding: gzip, deflate, br, zstd
Accept-Language: en-US,en;q=0.9
Connection: close
Host: localhost:5173
Referer: https://localhost:5173/
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36 Edg/143.0.0.0
sec-ch-ua-platform: "Windows"
sec-ch-ua: "Microsoft Edge";v="143", "Chromium";v="143", "Not A(Brand";v="24"
sec-ch-ua-mobile: ?0
sec-fetch-site: same-origin
sec-fetch-mode: cors
sec-fetch-dest: empty
priority: u=1, i
2026-01-08 20:40:15 [INF] Executing endpoint 'HospitalProject.Server.Controllers.WeatherForecastController.Get (HospitalProject.Server)'
2026-01-08 20:40:15 [INF] Executing endpoint 'HospitalProject.Server.Controllers.WeatherForecastController.Get (HospitalProject.Server)'
2026-01-08 20:40:15 [INF] Route matched with {action = "Get", controller = "WeatherForecast"}. Executing controller action with signature System.Collections.Generic.IEnumerable`1[HospitalProject.Server.WeatherForecast] Get() on controller HospitalProject.Server.Controllers.WeatherForecastController (HospitalProject.Server).
2026-01-08 20:40:15 [INF] Route matched with {action = "Get", controller = "WeatherForecast"}. Executing controller action with signature System.Collections.Generic.IEnumerable`1[HospitalProject.Server.WeatherForecast] Get() on controller HospitalProject.Server.Controllers.WeatherForecastController (HospitalProject.Server).
2026-01-08 20:40:15 [INF] Executing ObjectResult, writing value of type 'HospitalProject.Server.WeatherForecast[]'.
2026-01-08 20:40:15 [INF] Executing ObjectResult, writing value of type 'HospitalProject.Server.WeatherForecast[]'.
2026-01-08 20:40:15 [INF] Response:
StatusCode: 200
Content-Type: application/json; charset=utf-8
2026-01-08 20:40:15 [INF] Response:
StatusCode: 200
Content-Type: application/json; charset=utf-8
Response sent: https://localhost:44300/weatherforecast with HTTP status 200.0
Response sent: https://localhost:44300/weatherforecast with HTTP status 200.0
Response sent: https://localhost:44300/weatherforecast with HTTP status 200.0
Response sent: https://localhost:44300/weatherforecast with HTTP status 200.0
2026-01-08 20:40:15 [INF] Executed action HospitalProject.Server.Controllers.WeatherForecastController.Get (HospitalProject.Server) in 32.7467ms
2026-01-08 20:40:15 [INF] Executed action HospitalProject.Server.Controllers.WeatherForecastController.Get (HospitalProject.Server) in 35.7133ms
2026-01-08 20:40:15 [INF] Executed endpoint 'HospitalProject.Server.Controllers.WeatherForecastController.Get (HospitalProject.Server)'
2026-01-08 20:40:15 [INF] Executed endpoint 'HospitalProject.Server.Controllers.WeatherForecastController.Get (HospitalProject.Server)'
2026-01-08 20:40:15 [INF] ResponseBody: [{"date":"2026-01-09","temperatureC":9,"temperatureF":48,"summary":"Bracing"},{"date":"2026-01-10","temperatureC":47,"temperatureF":116,"summary":"Hot"},{"date":"2026-01-11","temperatureC":-18,"temperatureF":0,"summary":"Sweltering"},{"date":"2026-01-12","temperatureC":41,"temperatureF":105,"summary":"Mild"},{"date":"2026-01-13","temperatureC":47,"temperatureF":116,"summary":"Warm"}]
2026-01-08 20:40:15 [INF] ResponseBody: [{"date":"2026-01-09","temperatureC":39,"temperatureF":102,"summary":"Mild"},{"date":"2026-01-10","temperatureC":19,"temperatureF":66,"summary":"Bracing"},{"date":"2026-01-11","temperatureC":50,"temperatureF":121,"summary":"Scorching"},{"date":"2026-01-12","temperatureC":-19,"temperatureF":-2,"summary":"Balmy"},{"date":"2026-01-13","temperatureC":5,"temperatureF":40,"summary":"Balmy"}]
2026-01-08 20:40:15 [INF] Duration: 59.0387ms
2026-01-08 20:40:15 [INF] Duration: 59.1031ms
2026-01-08 20:40:15 [INF] HTTP GET /weatherforecast responded 200 in 64.0138 ms
2026-01-08 20:40:15 [INF] HTTP GET /weatherforecast responded 200 in 65.0056 ms
Response sent: https://localhost:44300/weatherforecast with HTTP status 200.0
Response sent: https://localhost:44300/weatherforecast with HTTP status 200.0
2026-01-08 20:40:15 [INF] Request finished HTTP/1.1 GET https://localhost:5173/weatherforecast - 200 null application/json; charset=utf-8 93.6509ms
2026-01-08 20:40:15 [INF] Request finished HTTP/1.1 GET https://localhost:5173/weatherforecast - 200 null application/json; charset=utf-8 93.4147ms
```

# A new set of launch configs (brining together IIS Express and Vite)
Although, I'm almost half way there with my setup and not the setup I exactly wanted. But this is still worth some launch configuration settings. I've written a bunch of PowerShell and **appcmd.exe** in IIS Express code to somewhat do a semi automated operations. There are few reasons why I did this:  
* This is fun and relaxing (some of my medication is causing me pain, this is a good way to take my mind of things).
* It's a good way to make sure your configurations are correct and valid (In my current state, I know the pain causes me to make mistakes).

I think it's a good way to incorporate with tasks and launch settings to make sure everything is good. 

So the first (set of) configs should be for IIS Express.

## IIS Express task and launch configurations


# References
* [Download Internet Information Services (IIS) 10.0 Express from Official Microsoft Download Center](https://www.microsoft.com/en-us/download/details.aspx?id=48264)
* [Host ASP.NET Core on Windows with IIS | Microsoft Learn](https://learn.microsoft.com/en-us/aspnet/core/host-and-deploy/iis/?view=aspnetcore-10.0)
* [Using the Windows System Tray to Manage Websites and Applications | Microsoft Learn](https://learn.microsoft.com/en-us/iis/extensions/using-iis-express/using-the-windows-system-tray-to-manage-websites-and-applications)
* [Getting Started with AppCmd.exe | Microsoft Learn](https://learn.microsoft.com/en-us/iis/get-started/getting-started-with-iis/getting-started-with-appcmdexe)
* [Advanced configuration | Microsoft Learn](https://learn.microsoft.com/en-us/aspnet/core/host-and-deploy/iis/advanced?view=aspnetcore-10.0#create-the-iis-site)
* [web.config file | Microsoft Learn](https://learn.microsoft.com/en-us/aspnet/core/host-and-deploy/iis/web-config?view=aspnetcore-10.0#set-environment-variables)
* [Debugging](https://code.visualstudio.com/docs/csharp/debugging#_attaching-to-a-process)