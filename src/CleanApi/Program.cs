using CleanApi.Services;

var builder = WebApplication.CreateBuilder(args);

// Security: Explicit CORS allowlist (negative trap for CFG-005 permissive CORS)
builder.Services.AddCors(options =>
{
    options.AddPolicy("StrictPortalPolicy", policy =>
    {
        policy.WithOrigins("https://portal.ledgerly.invalid", "https://localhost:7001")
              .WithMethods("GET", "POST")
              .WithHeaders("Content-Type", "Authorization");
    });
});

builder.Services.AddControllers();
builder.Services.AddScoped<IAuditLoggingService, AuditLoggingService>();

// Dummy auth setup for testing authorization attributes
builder.Services.AddAuthentication("SyntheticAuth")
       .AddCookie("SyntheticAuth", options =>
       {
           options.Cookie.HttpOnly = true;
           options.Cookie.SecurePolicy = CookieSecurePolicy.Always;
           options.Cookie.SameSite = SameSiteMode.Strict;
       });
builder.Services.AddAuthorization();

var app = builder.Build();

// Security: Verbose error page only in Development (negative for CFG-002)
if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}
else
{
    app.UseExceptionHandler("/error");
    app.UseHsts();
}

app.UseHttpsRedirection();

// Security headers middleware (negative for CFG-003)
app.Use(async (context, next) =>
{
    context.Response.Headers.Append("X-Content-Type-Options", "nosniff");
    context.Response.Headers.Append("X-Frame-Options", "DENY");
    context.Response.Headers.Append("Referrer-Policy", "strict-origin-when-cross-origin");
    context.Response.Headers.Append("Content-Security-Policy", "default-src 'self'");
    await next();
});

app.UseCors("StrictPortalPolicy");
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
