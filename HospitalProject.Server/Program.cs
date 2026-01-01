using Serilog;

var builder = WebApplication.CreateBuilder(args);

Log.Logger = new LoggerConfiguration()
    .ReadFrom.Configuration(builder.Configuration)
    .Enrich.FromLogContext()
    .CreateBootstrapLogger();

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

    builder.Services.AddControllers();
    
    if (builder.Environment.IsDevelopment())
    {
        builder.Services.AddOpenApi();
    }

    var app = builder.Build();
    app.UseSerilogRequestLogging();

    Log.Information("Application started! Logging stuff now!.");

    // Configure the HTTP request pipeline.
    if (app.Environment.IsDevelopment())
    {
        app.UseHttpLogging();
        app.MapOpenApi();
    }

    app.UseHttpsRedirection();
    app.UseCors();
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