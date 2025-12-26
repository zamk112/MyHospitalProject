# Introduction
The first thing I want to do is to do a scaffold install of ASP.NET Core Web API and ReactJS (Typescript) version. For ASP.NET Core Web API Backend, I am also going to use [Bruno](https://www.usebruno.com/) (an alternative to Postman) to test my API calls. For ReactJS, as long as the project launches that's a good enough but pretty sure HTTPS won't be configured out of the box, which I will do later.

# ASP.NET Core Scaffold Install
I'm going to start off with creating the ASP.NET Core Web API solution. So first thing is to make sure that you have the dotnet SDK installed. As of writing this documentation; I am using dotnet core 10.0. And you will also need to install certificates on your machine as well with this command:  
```cmd
    dotnet dev-certs https --trust
```

I've already done it before starting this tutorial so I don't have an output to show you at the moment. Once you have it installed, run the following the command:  
```cmd
    dotnet new webapi --use-controllers -o HospitalProject.Server 
```

You're output should look like this:  
```cmd
    MyHospitalProject> dotnet new webapi --use-controllers -o HospitalProject.Server                                                                                                                                        
    The template "ASP.NET Core Web API" was created successfully.

    Processing post-creation actions...
    Restoring Z:\Projects\MyHospitalProject\HospitalProject.Server\HospitalProject.Server.csproj:
    Restore succeeded.
```

This will create an ASP.NET Core controller based web API project with the Weather Forecast endpoint. And you should see this something like this in your directory.  
![ASP.NET Core Project Creation](./images/Screenshot%202025-12-26%20at%203.00.01 am.png)

I'm going to start it up and see what happens with this command:  
```cmd
    dotnet run -lp "https" --project HospitalProject.Server
```

In the console, we should see an output like this:  
```cmd
    MyHospitalProject> dotnet run -lp "https" --project HospitalProject.Server                                                                                                                                              
    Using launch settings from HospitalProject.Server\Properties\launchSettings.json...
    Building...
    info: Microsoft.Hosting.Lifetime[14]
        Now listening on: https://localhost:7276
    info: Microsoft.Hosting.Lifetime[14]
        Now listening on: http://localhost:5075
    info: Microsoft.Hosting.Lifetime[0]
        Application started. Press Ctrl+C to shut down.
    info: Microsoft.Hosting.Lifetime[0]
        Hosting environment: Development
    info: Microsoft.Hosting.Lifetime[0]
        Content root path: Z:\Projects\MyHospitalProject\HospitalProject.Server
```

So far it is working and no compilation errors as expected. Now I'm going to test the endpoints with Bruno. Looks like HTTPs version is working.  
![Bruno API call to weatherforecast HTTPS endpoint](./images/Screenshot%202025-12-26%20at%208.00.59 pm.png)

And the HTTP version is also working.  
![Bruno API call to weatherforecast HTTPS endpoint](./images/Screenshot%202025-12-26%20at%208.03.48 pm.png)

With ASP.NET Core version 8, you had Swagger UI for testing and API documentation, but in ASP.NET Core version 10 you have open API, which returns a JSON document.  
![Bruno API call to OpenAPI documentation](./images/Screenshot%202025-12-26%20at%208.09.15 pm.png)

Nice so we get a JSON formatted documentation of the API endpoints. 

Next is the ReactJS scaffolding install. 

# ReactJS Scaffold Install
For installing ReactJS scaffold, I'm going to use Vite. Make sure [nodeJS](https://nodejs.org/en) is also installed on your machine before you start running this command:  
```cmd
    npm create vite@latest
```

This is my output from the console:  
```cmd
    MyHospitalProject> npm create vite@latest                                                                                                                                                                               
    Need to install the following packages:
    create-vite@8.2.0
    Ok to proceed? (y) y


    > npx
    > create-vite

    │
    ◇  Project name:
    │  HospitalProject.Client
    │
    ◇  Package name:
    │  hospitalproject-client
    │
    ◇  Select a framework:
    │  React
    │
    ◇  Select a variant:
    │  TypeScript + React Compiler
    │
    ◇  Use rolldown-vite (Experimental)?:
    │  No
    │
    ◇  Install with npm and start now?
    │  Yes
    │
    ◇  Scaffolding project in Z:\Projects\MyHospitalProject\HospitalProject.Client...
    │
    ◇  Installing dependencies with npm...

    added 176 packages, and audited 177 packages in 45s

    45 packages are looking for funding
    run `npm fund` for details

    found 0 vulnerabilities
    │
    ◇  Starting dev server...

    > hospitalproject-client@0.0.0 dev
    > vite


    VITE v7.3.0  ready in 1566 ms

    ➜  Local:   http://localhost:5173/
    ➜  Network: use --host to expose
    ➜  press h + enter to show help
```   


Because I also started the server, it is running with HTTP. But now, as a part of my checking, I can see the website is working.  
![Launched ReactJS Website](./images/Screenshot%202025-12-26%20at%208.20.45 pm.png)

# Conclusion
So far everything is working, but we need to make some changes. Both frontend and backends needs to be running with HTTPS protocol not HTTP and some cleanup is required in the project is also needed as well. But will this in the next documentation.

# References
* [Tutorial: Create a controller-based web API with ASP.NET Core | Microsoft Learn](https://learn.microsoft.com/en-us/aspnet/core/tutorials/first-web-api?view=aspnetcore-10.0&tabs=visual-studio-code)
* [Generate OpenAPI documents | Microsoft Learn](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/openapi/aspnetcore-openapi?view=aspnetcore-10.0&tabs=net-cli%2Cvisual-studio-code)
* [Getting Started | Vite](https://vite.dev/guide/)