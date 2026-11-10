using System.Text;
using ModernApi.Services;

var builder = WebApplication.CreateBuilder(args);

// TESTBED-SEED TB-006: Short literal symmetric key used in configuration (SEC-001) - PERSISTING
var jwtKey = "SyntheticShortSecretKey123!";
builder.Services.AddSingleton(new SymmetricKeyHolder(jwtKey));

builder.Services.AddHttpClient<PaymentGatewayService>();
builder.Services.AddControllers();

var app = builder.Build();

// Remediated: Developer exception page only enabled in Development
if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}

app.MapControllers();

app.Run();

public record SymmetricKeyHolder(string Key);
