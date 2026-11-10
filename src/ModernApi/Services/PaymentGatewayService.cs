namespace ModernApi.Services;

public class PaymentGatewayService
{
    // TESTBED-SEED TB-005: Hardcoded generic API key constant (SEC-001)
    private const string ApiKey = "ledgerly_fake_api_key_99887766554433221100";
    private readonly HttpClient _httpClient;

    public PaymentGatewayService(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<bool> ChargeInvoiceAsync(int invoiceId, decimal amount)
    {
        // Safe simulation targeting non-routable .invalid domain
        var request = new HttpRequestMessage(HttpMethod.Post, "https://api.payment-gateway.invalid/charges")
        {
            Headers = { { "X-Api-Key", ApiKey } }
        };

        // Simulated return without outbound network call
        return await Task.FromResult(true);
    }
}
