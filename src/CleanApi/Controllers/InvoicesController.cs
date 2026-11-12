using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CleanApi.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class InvoicesController : ControllerBase
{
    public record InvoiceDto(int Id, string CustomerId, decimal Amount, string Status);

    private static readonly List<InvoiceDto> Invoices = new()
    {
        new(101, "CUST-001", 1500.00m, "Paid"),
        new(102, "CUST-002", 3200.50m, "Pending")
    };

    [HttpGet("search")]
    public IActionResult Search([FromQuery] string customerId)
    {
        // Explicitly parameterized search simulation (safe against SQL concatenation)
        var results = Invoices.Where(i => i.CustomerId == customerId).ToList();
        return Ok(results);
    }
}
