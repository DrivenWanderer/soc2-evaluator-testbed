using CleanApi.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CleanApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IAuditLoggingService _auditLogger;

    public AuthController(IAuditLoggingService auditLogger)
    {
        _auditLogger = auditLogger;
    }

    public record LoginRequest(string Username, string Password);

    [HttpPost("login")]
    [AllowAnonymous]
    public IActionResult Login([FromBody] LoginRequest request)
    {
        var ip = HttpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";

        if (string.IsNullOrWhiteSpace(request.Username) || string.IsNullOrWhiteSpace(request.Password))
        {
            _auditLogger.LogAuthenticationFailure(request.Username ?? "empty", ip, "Missing credentials");
            return BadRequest("Username and password are required.");
        }

        // CleanApi dummy validation
        if (request.Username == "admin" && request.Password == "CleanPortalPass2026!")
        {
            _auditLogger.LogAuthenticationSuccess(request.Username, ip);
            return Ok(new { token = "synthetic-clean-jwt-token-placeholder", username = request.Username });
        }

        _auditLogger.LogAuthenticationFailure(request.Username, ip, "Invalid credentials");
        return Unauthorized("Invalid credentials.");
    }
}
