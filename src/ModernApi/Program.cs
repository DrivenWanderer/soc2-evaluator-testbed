using System.Text;
using ModernApi.Services;

var builder = WebApplication.CreateBuilder(args);

// TESTBED-SEED TB-006: Short literal symmetric key used in configuration (SEC-001)
var jwtKey = "SyntheticShortSecretKey123!";
builder.Services.AddSingleton(new SymmetricKeyHolder(jwtKey));

builder.Services.AddHttpClient<PaymentGatewayService>();
builder.Services.AddControllers();

var app = builder.Build();

// TESTBED-SEED TB-003: Verbose developer exception page with no environment check (CFG-002)
app.UseDeveloperExceptionPage();

app.MapControllers();

app.Run();

public record SymmetricKeyHolder(string Key);
