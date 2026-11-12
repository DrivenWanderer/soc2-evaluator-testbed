using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json;

namespace ModernApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class InvoicesController : ControllerBase
{
    public record InvoiceRecord(int Id, string CustomerId, decimal Amount, string Status);

    private static readonly List<InvoiceRecord> SampleInvoices = new()
    {
        new(1, "ACME-CORP", 450.00m, "Paid"),
        new(2, "GLOBEX", 1200.75m, "Pending")
    };

    [HttpGet("search")]
    public IActionResult Search([FromQuery] string query)
    {
        // Direct usage of vulnerable Newtonsoft.Json 12.0.3 dependency (DEP-001)
        var serialized = JsonConvert.SerializeObject(SampleInvoices);
        return Content(serialized, "application/json");
    }
}
