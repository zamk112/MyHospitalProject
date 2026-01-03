# Motivation
Just want to give you a background for creating this project. At one of my previous jobs, the following happened:  
* 2 Weeks before go live, I got handed a broken AngularJS and ASP.NET Core project.
* Although I managed to make it to go-live it still had a lot of problems, but not going to mention what they were.
* Because of those problems I had to rewrite the application again but I did with ReactJS with SSR and ASP.NET Core backend to make it work (there's a reason why I chose SSR, let's just say it was to make it work with their infrastructure).
* I won't mention the details unless it's a job interview 😂.
* I was close to finishing it but because working 60-80 hour weeks for almost five months, I ended up in the hospital with heart problems and kidney damage ☠️.

Due to the short amount of time I had and because I ended up in hospital, there's a lot of things that I could have done better and things I didn't get to finish. This project is for a next time (maybe) if I am in an situation where I need to develop an application with ReactJS and ASP.NET Core WebAPI and host it on IIS. So in this project I'll be mostly be focusing on:
* Security,
* Authentication and Authorisation,
* Setting up for local development, testing,
* Deployment of both the frontend and backend on a IIS Server.

This is going to be like a template for doing this type of development. And I'm hoping this will help you out if you get stuck as well.

# Introduction
Now that's out of the way, now I want to focus on the things I want to do with this project:  
* HTTPS frontend and backend endpoints,
* Setting up for development for IIS,
* ODIC with Cookie integration (SSO login, going to [Auth0](https://auth0.com) for this),
* Implementing a reverse proxy on IIS, so the backend API does not get exposed,
* Cookie passthrough through reverse proxy setup,
* ACL and Frontend handling and integration,
* ASP.NET Core optimisations for IIS and IIS configuration for ASP.NET Core,
* Maybe React SSR setup,
* ACL with utilizing claims and roles,
* Global Logging.

I'm going to use VS Code for my development as well because, I like doing things the hard way when I'm learning especially when it comes to coding! And will be using the latest version of React (Typescript, Of course!) and ASP.NET Core.

And I'm developing this code on Windows 11 ARM which is running on Parallels VM which is running on my MacBook Air. Although I mentioned IIS, for local development and testing, I do plan (or at least try to) utilize IIS Express in order to get it close when the app is running on IIS Server.

# Table of Contents
* [Initial Commit](./Documentation/00_InitCommit.md)
* [Setting up for Local Development](./Documentation/01_SetupForLocalDevelopment.md)
