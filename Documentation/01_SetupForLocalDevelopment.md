# Introduction 
Now that I have installed the scaffolding for both ASP.NET Core WebApi backend and ReactJS frontend. I want to do a little bit of a cleanup and make sure for starters, everything is going to be running on HTTPs protocol. First going to start off with cleaning up HospitalProject.Server project and then the HospitalProject.Client project.

# HospitalProject.Server (ASP.NET Core Web API)
## Deleting the **HospitalProject.Server.http** file
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

    if (builder.Environment.IsDevelopment())
    {
        builder.Services.AddOpenApi();
    }

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

I had to move some stuff around, because I am using `try-catch-finally` block because if the app stops running or the user stops the app the logs needs to be closed and the buffer needs to be flushed out with `Log.CloseAndFlush();`. Before I go on about the logger configuration, I wrapped the `app.MapOpenApi();` in an `if` statement and make sure it is only initialised in development mode.  
```csharp
if (builder.Environment.IsDevelopment())
{
    builder.Services.AddOpenApi();
}
...
```

I don't like to add unnecessary things for the production build. But going back to the logger configuration, I followed the two-stage initialization first by creating a bootstrap with `.CreateBootstrapLogger();` when I'm intialising the logger and then adding SerialLog as a service to replace the original logger completely once the host is loaded with:  
```csharp
    builder.Services.AddSerilog((services, lc) => lc
        .ReadFrom.Configuration(builder.Configuration)
        .ReadFrom.Services(services)
        .Enrich.FromLogContext()
    );
```

And lastly, I added the Serilog middleware with `app.UseSerilogRequestLogging();` just before the initialisation of the `app` variable.

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

### Adding HTTP Logging Middleware
Since I'm trying to implement a reverse proxy setup with my web application stack. For debugging purposes I also added the `AddHttpLogging()` and `UseHttpLogging()` to capture my request for debugging later. At the moment it is setup for development mode.  
```csharp
    var builder = WebApplication.CreateBuilder(args);

    Log.Logger = new LoggerConfiguration()
        .ReadFrom.Configuration(builder.Configuration)
        .Enrich.FromLogContext()
        .CreateBootstrapLogger();

    if (builder.Environment.IsDevelopment())
    {
        builder.Services.AddHttpLogging(o => { 
            o.LoggingFields = HttpLoggingFields.All; 
            o.RequestHeaders.Add("Referer");
            o.RequestHeaders.Add("sec-ch-ua-platform");
            o.RequestHeaders.Add("sec-ch-ua");
            o.RequestHeaders.Add("sec-ch-ua-mobile");
            o.RequestHeaders.Add("sec-fetch-site");
            o.RequestHeaders.Add("sec-fetch-mode");
            o.RequestHeaders.Add("sec-fetch-dest");
            o.RequestHeaders.Add("priority");
        }); // In development mode only
    }
    ...
    var app = builder.Build();
    app.UseSerilogRequestLogging();

    Log.Information("Application started! Logging to both console and file.");

    // Configure the HTTP request pipeline.
    if (app.Environment.IsDevelopment())
    {
        app.UseHttpLogging(); // In development mode only
        app.MapOpenApi();
    }
```
The outputs will appear in the console and logs as well which shows something like this:  
```cmd

2025-12-31 22:15:14 [INF] Request:
Protocol: HTTP/1.1
Method: GET
Scheme: https
PathBase: 
Path: /weatherforecast
Accept: application/json, text/plain, */*
Connection: keep-alive
Host: localhost:7276
User-Agent: bruno-runtime/2.15.1
Accept-Encoding: gzip, compress, deflate, br
request-start-time: [Redacted]
2025-12-31 22:15:14 [INF] Executing endpoint 'HospitalProject.Server.Controllers.WeatherForecastController.Get (HospitalProject.Server)'
2025-12-31 22:15:15 [INF] Route matched with {action = "Get", controller = "WeatherForecast"}. Executing controller action with signature System.Collections.Generic.IEnumerable`1[HospitalProject.Server.WeatherForecast] Get() on controller HospitalProject.Server.Controllers.WeatherForecastController (HospitalProject.Server).
2025-12-31 22:15:15 [INF] Executing ObjectResult, writing value of type 'HospitalProject.Server.WeatherForecast[]'.
2025-12-31 22:15:15 [INF] Executed action HospitalProject.Server.Controllers.WeatherForecastController.Get (HospitalProject.Server) in 44.1933ms
2025-12-31 22:15:15 [INF] Executed endpoint 'HospitalProject.Server.Controllers.WeatherForecastController.Get (HospitalProject.Server)'
2025-12-31 22:15:15 [INF] Response:
StatusCode: 200
Content-Type: application/json; charset=utf-8
Date: Wed, 31 Dec 2025 11:15:14 GMT
Server: Kestrel
Transfer-Encoding: chunked
2025-12-31 22:15:15 [INF] HTTP GET /weatherforecast responded 200 in 84.0014 ms
2025-12-31 22:15:15 [INF] Request finished HTTP/1.1 GET https://localhost:7276/weatherforecast - 200 null application/json; charset=utf-8 115.435
```

After you have setup your front end, you will need to add headers that you want to capture. This is after I set up my ReactJS frontend for adding additional logging for the headers that I wanted to capture in debug mode.  
```csharp
...
builder.Services.AddHttpLogging(o => { 
    o.LoggingFields = HttpLoggingFields.All; 
    o.RequestHeaders.Add("Referer");
    o.RequestHeaders.Add("sec-ch-ua-platform");
    o.RequestHeaders.Add("sec-ch-ua");
    o.RequestHeaders.Add("sec-ch-ua-mobile");
    o.RequestHeaders.Add("sec-fetch-site");
    o.RequestHeaders.Add("sec-fetch-mode");
    o.RequestHeaders.Add("sec-fetch-dest");
    o.RequestHeaders.Add("priority");
});
...
```

I might have to set some limits on the HTTP Logging later, but for now this is good enough to start off with.

## Bruno Does not trust the Certificate Trust Store in Windows
I was initially documenting how to generate a pem certificate file and add it Certificate to Bruno but unfortunately, Bruno does not trust the certificate trust store as per [Unable to verify the first certificate, self-signed certificate not working? · Issue #4949 · usebruno/bruno](https://github.com/usebruno/bruno/issues/4949). And it appears neither does Postman. So I'll have to change gears later down the track when I have front end and backend working together with a proxy setup and use Python to do the API calls. But for now Bruno does the job so still will use and if they fix it even better 😊.

## Adding CORS
I'm going to add CORS to only allow certain URLs access the APIs for local development. We'll need to come back and end for IIS Express and for IIS.  
```csharp
...
try
{
    if (builder.Environment.IsDevelopment())
    {
        builder.Services.AddHttpLogging(o => { });
    }

    builder.Services.AddSerilog((services, lc) => lc
        .ReadFrom.Configuration(builder.Configuration)
        .ReadFrom.Services(services)
        .Enrich.FromLogContext()
    );

    builder.Services.AddCors(options =>
    {
        options.AddDefaultPolicy(policy =>
        {
            policy.WithOrigins("https://localhost:5173", "https://localhost:7276") 
                  .AllowAnyHeader()
                  .AllowAnyMethod();
        });
    });
    ...
    var app = builder.Build();
    ...
    app.UseHttpsRedirection();
    app.UseCors();
    ...
}
...
``` 

At the moment, I'm just allowing everything on the local dev setup. I don't want any funny business outside from my VM, since I'm running everything from the inside. 

# Vite SSL configuration for ReactJS Frontend
When I ran `npm run dev`, it's running with the HTTP protocol:  
```cmd
> npm run dev                                                                           

> hospitalproject-client@0.0.0 dev
> vite


  VITE v7.3.0  ready in 3121 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
  ➜  press h + enter to show help
```

And Edge is complaining my website is *not secure*:  
![Edge saying my website is not secure.... Oh no 😭](./images/Screenshot%202026-01-01%20at%2012.26.02 am.png)

Lets make it sure and get started for configuration Vite with SSL configuration for hosting the ReactJS frontend!

## SSL certificate generation
First thing I need to do is to generate the SSL pem certificate and store it somewhere.  I'm going to put it in my **%LOCALAPPDATA%\ASP.NET\https** folder. And I'm going to generate the certificate with the dotnet tool with the following command (Sorry, using PowerShell, I know looks horrible, kinda rusty with cmd script):  
```pwsh
if (-not(Test-Path -LiteralPath $env:LOCALAPPDATA\ASP.NET\https\hospitalproject.client.pem -PathType Leaf) -or 
    -not(Test-Path -LiteralPath $env:LOCALAPPDATA\ASP.NET\https\hospitalproject.client.key -PathType Leaf)) 
{ 
    if (-not(Test-Path -LiteralPath $env:LOCALAPPDATA\ASP.NET\https -PathType Container))
    {
       New-Item -Path $env:LOCALAPPDATA\ASP.NET\https -ItemType Directory
    }
    "dotnet dev-certs https -ep $($env:LOCALAPPDATA)\ASP.NET\https\hospitalproject.client.pem --format pem -np" | cmd 
} 
```

This should generate a **\*.pem** and **\*.key** file in the directory:  
```pwsh
> Get-ChildItem $env:LOCALAPPDATA\ASP.NET\https              

    Directory: C:\Users\zamk1\AppData\Local\ASP.NET\https

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a---          31/12/2025 11:53 PM           1703 hospitalproject.client.key
-a---          31/12/2025 11:53 PM           1349 hospitalproject.client.pem
```

At the moment the **vite.config.ts** file looks pretty barren.  
```ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    react({
      babel: {
        plugins: [['babel-plugin-react-compiler']],
      },
    }),
  ],
})

```

But it will get bigger in the next section (just a little bit).

## Updating **vite.config.ts** file
### Adding SSL encryption to website
Now I need to start modifying **vite.config.ts** file and make the site hosting with SSL enabled. The first thing I need to is check if the directory contains my certificates, if it does great, if it doesn't vite should throw an error not start the server.  

```ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'node:path';
import fs from 'node:fs';

const certName = 'hospitalproject.client';
const certFolder = path.join(`${process.env.LOCALAPPDATA}`, 'ASP.NET', 'https');
const certPath = path.join(certFolder, `${certName}.pem`);
const keyPath = path.join(certFolder, `${certName}.key`);

if (!fs.existsSync(certPath) || !fs.existsSync(keyPath)) {
  throw new Error('Development certificate not found.');
}
...
```

The first part is done. Using `path.join` to build my directory and file paths and then checking it with `fs.existsSync` if the certificates exists, if it doesn't it will throw an error. The next part is to make the ReactJS frontend use SSL and use HTTPS.  

```ts
...
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
  },
```

I kept the port the same as what you get when you create a ReactJS (TypeScript) project, but you don't have to add it because it defaults to this port anyways (I just have bad memory and forget where the port number comes from so I documented it 😅). But I had to reference my SSL pem and key files to it. When I run the `npm run dev` command, I'm getting an output like this.  
```cmd
> npm run dev

> hospitalproject-client@0.0.0 dev
> vite


  VITE v7.3.0  ready in 1053 ms

  ➜  Local:   https://localhost:5173/
  ➜  Local:   https://vite.dev.localhost:5173/
  ➜  Local:   https://vite.dev.internal:5173/
  ➜  Local:   https://host.docker.internal:5173/
  ➜  Local:   https://host.containers.internal:5173/
  ➜  Network: use --host to expose
  ➜  press h + enter to show help
``` 

Everything now is running with HTTPS protocol so far good. When I click the `https://localhost:5173/` url, I can see now that Edge is saying the website is secure.  
![Website now secure 👍](./images/Screenshot%202026-01-01%20at%203.59.23 pm.png)

### Setting up the Proxy to backend API calls
The next thing is to setup a proxy for the backend to be called.  
```ts
...
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

As you can see I have added a `proxy` configuration where it takes in a `Record<string, string | ProxyOptions>` type. The `target` is the URL for my ASP.NET Core backend endpoint. I set the `secure` property to `true` so it has to do SSL validation. The `'^/weatherforecast'` is a regex expression where it makes sure that the beginning starts with '/'. Going forward when I create more controllers with different endpoints. I need to map it to this `proxy` config in **vite.config.ts**. 

Before I go any further I need to add some code to **App.tsx** to do an API calls to the *weatherforcast* endpoint. 

### Adding some code in **App.tsx**
This is my front end code for doing an API call to *weatherforcast* endpoint.  
```tsx
import { useEffect, useRef, useState } from 'react';
...
function App() {
  const [count, setCount] = useState(0);
  const [forecasts, setForecasts] = useState<Forecast[]>();
  const hasFetchedRef = useRef(false);

  useEffect(() => {
    if (hasFetchedRef.current) return;
    hasFetchedRef.current = true;

    const populateWeatherForecasts = async () => {
      const response = await fetch('weatherforecast');
      if (response.ok) {
        const data = await response.json();
         setForecasts(data);
      }
    };
    
    populateWeatherForecasts();
  }, []);


  return (
    <>
    ...
      <div className="card">
        <div className="weather-forecasts">
          {!forecasts ? <p>Weather Forecast Loading...</p> : 
            <table>
              <thead>
                <tr>
                  <th>Date</th>
                  <th>Temp. (C)</th>
                  <th>Temp. (F)</th>
                  <th>Summary</th>
                </tr>
              </thead>
              <tbody>
                {forecasts.map((forecast, index) => (
                  <tr key={index}>
                    <td>{new Date(forecast.date).toLocaleDateString()}</td>
                    <td>{forecast.temperatureC}</td>
                    <td>{forecast.temperatureF}</td>
                    <td>{forecast.summary}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          }
      </div>        
      ...
    </>
  )
}
...
```

Nothing too fancy very similar to what you get in the scaffolded code when you create a new project in Visual Code 2022. As you can see when I call `fetch()`, I'm not passing the entire URL to my backend endpoint. Just `weatherforecast` and using `useRef()` so that `fetch()` does not get triggered twice because ReactJS is in **strict** mode. 

If I launch both back and front together, there is a problem! My `<table>` did not get rendered!  
![Webpage Loaded, but no table rendered](./images/Screenshot%202026-01-01%20at%209.06.25 pm.png)  

I'm going to open up the developer tool, refresh the page and see what's happening:  
![HTTP 500 error](./images/Screenshot%202026-01-01%20at%209.09.41 pm.png)

Oh no!, getting HTTP 500 error, I'm going to have a look at the output on the console of my ASP.NET Core app.  
```cmd
------------------------------------------------------------------------------
You may only use the Microsoft Visual Studio .NET/C/C++ Debugger (vsdbg) with
Visual Studio Code, Visual Studio or Visual Studio for Mac software to help you
develop and test your applications.
------------------------------------------------------------------------------
2026-01-01 21:05:46 [INF] Application started! Logging stuff now!.
2026-01-01 21:05:47 [INF] Now listening on: https://localhost:7276
2026-01-01 21:05:47 [INF] Application started. Press Ctrl+C to shut down.
2026-01-01 21:05:47 [INF] Hosting environment: Development
2026-01-01 21:05:47 [INF] Content root path: Z:\Projects\MyHospitalProject\HospitalProject.Server
```

No APIs calls made, so it's because it's failing at the front end with SSL validation. Let's see what the error message says:  
```cmd
> npm run dev

> hospitalproject-client@0.0.0 dev
> vite


  VITE v7.3.0  ready in 678 ms

  ➜  Local:   https://localhost:5173/
  ➜  Local:   https://vite.dev.localhost:5173/
  ➜  Local:   https://vite.dev.internal:5173/
  ➜  Local:   https://host.docker.internal:5173/
  ➜  Local:   https://host.containers.internal:5173/
  ➜  Network: use --host to expose
  ➜  press h + enter to show help
9:06:11 pm [vite] http proxy error: /weatherforecast
Error: self-signed certificate; if the root CA is installed locally, try running Node.js with --use-system-ca
    at TLSSocket.onConnectSecure (node:_tls_wrap:1631:34)
    at TLSSocket.emit (node:events:508:28)
    at TLSSocket._finishInit (node:_tls_wrap:1077:8)
    at ssl.onhandshakedone (node:_tls_wrap:863:12)
```

The problem is with NodeJS, well it's not really a problem more like a config issue. But basically at the moment NodeJS doesn't trust the Windows system trust store, where the ASP.NET Core developer certificate sits. The is simple, which I will explain in the next section. 

### How make NodeJS trust the Windows System trust store
So as the error says `try running Node.js with --use-system-ca`, but I'm running a npm command which the npm executes for me, so I can't really use `--use-system-ca` flag (and I tried 😅, you guys can tell me I'm wrong, maybe I did something wrong here). But I managed to get it to work in 2 ways:  
1. By PowerShell environment variables. In VS Code, if your terminal is a PowerShell terminal, before running the `npm run dev` command you need to run `$env:NODE_USE_SYSTEM_CA=1` first and then run `npm run dev` command.
2. You edit your environment variables and yes it will work under the user environment variables and the environment variables as per below.  
   ![Adding a user environment variable](./images/Screenshot%202026-01-01%20at%209.29.10 pm.png)

And now if you run it, it should be fine.
![Table now rendered on page](./images/Screenshot%202026-01-01%20at%209.33.04 pm.png)

No errors in the terminal.  
```cmd
> $env:NODE_USE_SYSTEM_CA=1
> npm run dev    

> hospitalproject-client@0.0.0 dev
> vite


  VITE v7.3.0  ready in 725 ms

  ➜  Local:   https://localhost:5173/
  ➜  Local:   https://vite.dev.localhost:5173/
  ➜  Local:   https://vite.dev.internal:5173/
  ➜  Local:   https://host.docker.internal:5173/
  ➜  Local:   https://host.containers.internal:5173/
  ➜  Network: use --host to expose
  ➜  press h + enter to show help
```

I went with option one, option two might be better but I don't like adding environment variables if I don't have to. Vite is using the [http-proxy-3](https://github.com/sagemathinc/http-proxy-3), which is a nodeJS package, in their documentation they said set `secure` to `false` for self-signed certificates but this is only for HTTP 2, I'm native HTTP/HTTPS or HTTPS 1.1 for local development which is good enough for me now.

One more thing I'd like to mention, when NodeJS implemented this fix; they're following the [Chromium's policy](https://chromium.googlesource.com/chromium/src/+/main/net/data/ssl/chrome_root_store/faq.md#how-does-the-chrome-certificate-verifier-integrate-with-platform-trust-stores-for-local-trust-decisions) of where the certificates will be stored. I also checked as well. The certificates are in *Trust -> Trusted Root Certification Authorities* under the user profile. If this doesn't work for you this is the first place I'd check.  

# Setting up VSCode Launch Profiles
So I've been using the **launchSettings.json** to launch my ASP.NET Core app and the ReactJS app from command line. Plus before launching my ReactJS app, I have to run `$env:NODE_USE_SYSTEM_CA=1` each time before otherwise the SSL verification doesn't work.

And I want to launch them both at the same time, not have to run `$env:NODE_USE_SYSTEM_CA=1` for SSL verification to work for ReactJS and also debug them too (ReactJS app, I want to use the Browser Debugger). And the good news is I can! When you create launch configurations, it will created in **/.vscode/launch.json**. Easiest way to get start is from the VS Code menu, click *Run -> Add Configurations* or create a **launch.json** file in **./vscode** directory.

## Launch config for ASP.NET Core
So **launchSettings.json** already has the configuration of how the ASP.NET Core web app should run (e.g. with running with HTTPS, specified port number and runtime as Kestrel) and I don't want to redefine this again. This is the config that I initially started off with:  
```json
    "version": "0.2.0",
    "configurations": [
        {
            "name": "ASP.NET Core Launch (https)",
            "type": "coreclr",
            "request": "launch",
            "preLaunchTask": "dotnet: build ${workspaceFolder}\\HospitalProject.Server\\HospitalProject.Server.csproj",
            "launchSettingsProfile": "https",
            "program": "${workspaceFolder}/HospitalProject.Server/bin/Debug/net10.0/HospitalProject.Server.dll",
            "args": [],
            "cwd": "${workspaceFolder}/HospitalProject.Server",
            "stopAtEntry": false,
            "env": {
                "ASPNETCORE_ENVIRONMENT": "Development"
            },
        },
    ]
```

Just going to focus the essentials here as I said previously, I do not want to redefine **launchSettings.json** and I haven't, `launchSettingsProfile` attribute value points to my config of `https` attribute in **launchSettings.json**. Next is the `preLaunchTask` attribute, this is essentially the build command for building the solution. I tried to format the paths like it is in `program` attribute but for some reason it did not work, So I created a task, which is in the **task.json** file and referenced it in this config, which I will discuss next. Lastly `name` attribute is a very important which I will come back to. 

### **task.json** file
So a task in **task.json** is a build step which you can use for building your application and/or launching your application. 

The quickest way to create a task on Windows is pressing *Ctrl+Shift+p* and then search for *Tasks: Configure Task*:  
![Tasks: Configure Task](./images/Screenshot%202026-01-03%20at%201.22.13 am.png)

And then another set of command palette dropdown will appear and then click on `dotnet: build`:  
![dotnet: build command](./images/Screenshot%202026-01-03%20at%201.23.29 am.png)

Or just create the **task.json** file in the **.vscode** directory 😊.

So in order to make it like the `program` attribute in **launchSettings.json**, this is what I came up with:  
```json
{
	"version": "2.0.0",
	"tasks": [
		{
			"type": "dotnet",
			"task": "build ${workspaceFolder}/HospitalProject.Server/HospitalProject.Server.csproj /property:GenerateFullPaths=true /p:Configuration=Debug /p:Platform=AnyCPU /consoleloggerparameters:NoSummary",
			"file": "${workspaceFolder}/HospitalProject.Server/HospitalProject.Server.csproj",
			"group": "build",
			"problemMatcher": [],
			"label": "dotnet local dev build"
		}
	]
}
```

Since I have defined this task to build my ASP.NET Core Web API endpoint in debug mode, all I need to do is reference it back in **launch.json** file for launching my ASP.NET Core Web API endpoint where `preLaunchTask` attribute is now pointing to the `label` attribute in **task.json**. So now, **launch.json** looks like this.  
```json
    "version": "0.2.0",
    "configurations": [
        {
            "name": "ASP.NET Core Launch (https)",
            "type": "coreclr",
            "request": "launch",
            "preLaunchTask": "dotnet local dev build",
            "launchSettingsProfile": "https",
            "program": "${workspaceFolder}/HospitalProject.Server/bin/Debug/net10.0/HospitalProject.Server.dll",
            "args": [],
            "cwd": "${workspaceFolder}/HospitalProject.Server",
            "stopAtEntry": false,
            "console": "internalConsole",
            "env": {
                "ASPNETCORE_ENVIRONMENT": "Development"
            },
        },
    ]
```

## ReactJS launch configuration
With ReactJS launch configuration this is what I have done.  

```json
    "version": "0.2.0",
    "configurations": [
        ...
        {
            "name": "Launch Reach App (Dev)",
            "type": "node",
            "request": "launch",
            "runtimeExecutable": "npm",
            "runtimeArgs": ["run","dev"],
            "cwd": "${workspaceFolder}/HospitalProject.Client",
            "console": "integratedTerminal",
            "skipFiles": [
                "${workspaceFolder}/node_modules/**/*.js"
            ],            
            "serverReadyAction": {
                "pattern": ".+Local:.+(https?:\/\/.+)",
                "uriFormat": "%s",
                "webRoot": "${workspaceFolder}/HospitalProject.Client",
                "action": "debugWithEdge"
            },
            "env": {
                "NODE_USE_SYSTEM_CA": "1"
            }
        },
    ],
```

I'm launching with NPM with the runtime arguments `run dev`, and I wanted to launch the website on my browser to do this, I had define the `console` attribute and it has to be `integratedTerminal` and `serverReadyAction` attribute. If the `console` attribute is not `integratedTerminal` it does not launch. 

In `serverReadyAction`, the only values you can set for the `action` attribute is `debugWithEdge` or `debugWithChrome`.

I like using the debugger on the chromium browsers so it worked out well for me. But I also added `skipFiles` attribute to exclude the files in the `node_modules` directory when I'm stepping through the code. Lastly, I set the environment variable with `"NODE_USE_SYSTEM_CA": "1"` so it I don't have to manually add it to the environment variables or set the environment variable in the PowerShell console before I run it, so yay!

## Launching both ASP.NET Core and ReactJS launch profiles
Bringing it all together now, I want launch both profiles together. This is what I have done to launch both of them.  
```json
"compounds": [
    {
        "name": "Launch Both Server and Client (Local Development)",
        "configurations": [
            "ASP.NET Core Launch (https)",
            "Launch Reach App (Dev)",
        ]
    }
]
```

This will launch both client and server at the same time. Notice in the `configurations` attribute I'm using the labels for both ASP.NET Core and ReactJS launch profiles. 

# References
* [Configure endpoints for the ASP.NET Core Kestrel web server | Microsoft Learn](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/servers/kestrel/endpoints?view=aspnetcore-10.0)
* [serilog/serilog-aspnetcore: Serilog integration for ASP.NET Core](https://github.com/serilog/serilog-aspnetcore?tab=readme-ov-file)
* [serilog/serilog-settings-configuration: A Serilog configuration provider that reads from Microsoft.Extensions.Configuration](https://github.com/serilog/serilog-settings-configuration)
* [HTTP logging in .NET and ASP.NET Core | Microsoft Learn](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/http-logging/?view=aspnetcore-10.0)
* [Unable to verify the first certificate, self-signed certificate not working? · Issue #4949 · usebruno/bruno](https://github.com/usebruno/bruno/issues/4949)
* [Server Options | Vite](https://vite.dev/config/server-options#server-https)
* [sagemathinc/http-proxy-3: Modern rewrite of node-proxy (the original nodejs http proxy server)](https://github.com/sagemathinc/http-proxy-3?tab=readme-ov-file#options)
* [Node.js — Enterprise Network Configuration](https://nodejs.org/en/learn/http/enterprise-network-configuration#adding-ca-certificates-from-the-system-store)
* [Node.js — Node.js v23.8.0 (Current)](https://nodejs.org/en/blog/release/v23.8.0)
* [Frequently Asked Questions](https://chromium.googlesource.com/chromium/src/+/main/net/data/ssl/chrome_root_store/faq.md#how-does-the-chrome-certificate-verifier-integrate-with-platform-trust-stores-for-local-trust-decisions)
* [List of configurable options](https://code.visualstudio.com/docs/csharp/debugger-settings)
* [Browser debugging in VS Code](https://code.visualstudio.com/docs/nodejs/browser-debugging)
* [Node.js debugging in VS Code](https://code.visualstudio.com/docs/nodejs/nodejs-debugging)
* [Visual Studio Code debug configuration](https://code.visualstudio.com/docs/debugtest/debugging-configuration)
* [.net - Debugging ReactJS Components in AspNet Core - Stack Overflow](https://stackoverflow.com/questions/66012523/debugging-reactjs-components-in-aspnet-core)