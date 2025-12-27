# Introduction 
Now that I have installed the scaffolding for both ASP.NET Core WebApi backend and ReactJS frontend. I want to do a little bit of a cleanup and make sure for starters, everything is going to be running on HTTPs protocol. First going to start off with cleaning up HospitalProject.Server project and then the HospitalProject.Client project.

# HospitalProject.Server (ASP.NET Core Web API)
## Deleting the HospitalProject.Server.http file
First thing I'm going to is delete the **HospitalProject.Server.http**, this file works with Visual Studio but not VS code (at least I can't find a plugin for this as yet). Plus I'm using Bruno to do my testing for API calls. Going to run a PS command (sorry cmd commands is a bit rusty on Windows):  
```pwsh
Remove-Item -Path .\HospitalProject.Server\HospitalProject.Server.http
```

## Launch setting profiles
Instead of running `dotnet run -lp "https" --project HospitalProject.Server` each time. I just want to run from VS code where I can go from the menu: Run -> Start Debugging. And I only want to run for HTTPS not for HTTP. Right now when you go Run -> Start Debugging from the VS code menu you get the following options:  
![Default Options in VSCode](./images/Screenshot%202025-12-26%20at%209.10.13 pm.png)

Having a look at **\HospitalProject.Server\Properties\launchSettings.json**, I can see there's two profiles for HTTP and HTTPS.  
```json
{
  "$schema": "https://json.schemastore.org/launchsettings.json",
  "profiles": {
    "http": {
      "commandName": "Project",
      "dotnetRunMessages": true,
      "launchBrowser": false,
      "applicationUrl": "http://localhost:5075",
      "environmentVariables": {
        "ASPNETCORE_ENVIRONMENT": "Development"
      }
    },
    "https": {
      "commandName": "Project",
      "dotnetRunMessages": true,
      "launchBrowser": false,
      "applicationUrl": "https://localhost:7276;http://localhost:5075",
      "environmentVariables": {
        "ASPNETCORE_ENVIRONMENT": "Development"
      }
    }
  }
}
```

I'm going to get rid of the `http` profile and keep the `https` profile but with slight modification and remove the `http` URL endpoint.  
```json
{
  "$schema": "https://json.schemastore.org/launchsettings.json",
  "profiles": {
    "https": {
      "commandName": "Project",
      "dotnetRunMessages": true,
      "launchBrowser": false,
      "applicationUrl": "https://localhost:7276",
      "environmentVariables": {
        "ASPNETCORE_ENVIRONMENT": "Development"
      }
    }
  }
}
```

And in [Program.cs](../HospitalProject.Server/Program.cs), I'm also going to leave `app.UseHttpsRedirection();` as is at the moment and not comment it out, but for local development everything will be HTTPS. I'm not going to setup CORS just yet as I have not started setting the React Frontend for local development. But I will come back to CORS later. But now when I do a API call from Bruno, only HTTPS should work and HTTP shouldn't.

Connection Refused when doing an API call to HTTP endpoint.  
![API call to HTTP endpoint failed](./images/Screenshot%202025-12-26%20at%2011.09.04 pm.png)

Working with HTTPS endpoint:  
![API call to HTTPS endpoint working](./images/Screenshot%202025-12-26%20at%2011.10.35 pm.png)

### `https` configuration missing in VS Code
When I tried to start up from the menu: Run -> Start Debugging, I got this error:
![Run and Debug Error](./images/Screenshot%202025-12-26%20at%2011.16.44 pm.png)

But from the command like it is working.  
![Running from command line](./images/Screenshot%202025-12-26%20at%2011.21.20 pm.png)

If you do want to run it from the menu: Run -> Start Debugging, make sure to set it to **C#: Launch Startup Project** as your option.  
![Running with option C#: Launch Startup Project](./images/Screenshot%202025-12-26%20at%2011.24.49 pm.png)

I think this could be a bug in VS code.  

### Out-of-the-box Processing Model
On a side note as of right now, I am running out-of-the-box processing model, which is running with Kestrel when I launch the ASP.NET Core application. [launchSettings.json](../HospitalProject.Server/Properties/launchSettings.json) is being used for local development. [appsettings.json](../HospitalProject.Server/appsettings.json) can be used for specific Kestrel configuration for configuring HTTP and HTTPS. But for now, I'm sticking to [launchSettings.json](../HospitalProject.Server/Properties/launchSettings.json) since I am using it for local development. IIS Express might be different, but I'll get to that once I start testing.

## Logging
The next things I want to setup is logging. I like using [Serilog](https://serilog.net) because for local development I can configure the logger to log stuff out to the console and also to a log file. This is because, just in case I have forget to capture the logs from the console. At least it will be saved in a file so I can comeback and reference later. The first thing I need to is to install it with the following CLI command:  
```cmd
dotnet add package Serilog.AspNetCore --project HospitalProject.Server
```

Once it is installed, we need to add some configuration to [Program.cs](../HospitalProject.Server/Program.cs), well actually it's a little more than just adding configuration.  
```csharp
using Serilog;

var builder = WebApplication.CreateBuilder(args);

Log.Logger = new LoggerConfiguration()
    .ReadFrom.Configuration(builder.Configuration)
    .Enrich.FromLogContext()
    .CreateBootstrapLogger();

try
{
    builder.Services.AddSerilog((services, lc) => lc
        .ReadFrom.Configuration(builder.Configuration)
        .ReadFrom.Services(services)
        .Enrich.FromLogContext()
    );
    builder.Services.AddControllers();
    builder.Services.AddOpenApi();

    var app = builder.Build();
    app.UseSerilogRequestLogging();

    Log.Information("Application started! Logging to both console and file.");

    // Configure the HTTP request pipeline.
    if (app.Environment.IsDevelopment())
    {
        app.MapOpenApi();
    }

    app.UseHttpsRedirection();
    app.UseAuthorization();
    app.MapControllers();
    app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "Application start-up failed!");
}
finally
{
    Log.CloseAndFlush();
}
```

After installing the package, the first thing I had was initialise the logger with:  
```csharp
Log.Logger = new LoggerConfiguration()
    .ReadFrom.Configuration(builder.Configuration)
    .Enrich.FromLogContext()
    .CreateBootstrapLogger();
```

I had to move some stuff around, because I am using `try-catch-finally` block because if the app stops running or the user stops the app the logs needs to be closed and the buffer needs to be flushed out with `Log.CloseAndFlush();`. But I followed the two-stage initialization first by creating a bootstrap with `.CreateBootstrapLogger();` when I'm intialising the logger and then adding SerialLog as a service to replace the original logger completely once the host is loaded with:  
```csharp
    builder.Services.AddSerilog((services, lc) => lc
        .ReadFrom.Configuration(builder.Configuration)
        .ReadFrom.Services(services)
        .Enrich.FromLogContext()
    );
```

And lastly, you add your Serilog middleware with `app.UseSerilogRequestLogging();` just before the initialisation of the `app` variable.

I like doing configuration from configuration files as much as possible. So in my [appsettings.Development.json](../HospitalProject.Server/appsettings.Development.json), this is the config that I have added to log stuff out to both console and to a log file:  
```json
{
  "Serilog": {
    "Using": ["Serilog.Sinks.Console", "Serilog.Sinks.File"],
    "MinimumLevel": {
      "Default": "Information"
    },
    "WriteTo": [
      {
        "Name": "Console",
        "Args": {
          "outputTemplate": "{Timestamp:yyyy-MM-dd HH:mm:ss} [{Level:u3}] {Message:lj}{NewLine}{Exception}"
        }
      },
      {
        "Name": "File",
        "Args": {
          "path": "Logs/app.log",
          "rollingInterval": "Day",
          "retainedFileCountLimit": 10,
          "fileSizeLimitBytes": 10485760,
          "outputTemplate": "{Timestamp:yyyy-MM-dd HH:mm:ss} [{Level:u3}] {Message:lj}{NewLine}{Exception}"
        }
      }
    ]
  }
}
```

And in [appsettings.json](../HospitalProject.Server/appsettings.json), I'm just logging out everything to a file sink, kinda treating [appsettings.json](../HospitalProject.Server/appsettings.json) as my production config file.  
```json
{
  "Serilog": {
    "Using": ["Serilog.Sinks.File"],
    "MinimumLevel": {
      "Default": "Warning"
    },
    "WriteTo": [
      {
        "Name": "File",
        "Args": {
          "path": "Logs/app.log",
          "rollingInterval": "Day",
          "retainedFileCountLimit": 10,
          "fileSizeLimitBytes": 10485760,
          "outputTemplate": "{Timestamp:yyyy-MM-dd HH:mm:ss} [{Level:u3}] {Message:lj}{NewLine}{Exception}"
        }
      }
    ]
  },
  "AllowedHosts": "*"
}
```

I don't know if this is considered global logging but it is logging everything from when the host starts. And when you call `AddSerilog()`, it registers it as a singleton. But for now, logging is good to go.

# References
* [Configure endpoints for the ASP.NET Core Kestrel web server | Microsoft Learn](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/servers/kestrel/endpoints?view=aspnetcore-10.0)
* [serilog/serilog-aspnetcore: Serilog integration for ASP.NET Core](https://github.com/serilog/serilog-aspnetcore?tab=readme-ov-file)
* [serilog/serilog-settings-configuration: A Serilog configuration provider that reads from Microsoft.Extensions.Configuration](https://github.com/serilog/serilog-settings-configuration)