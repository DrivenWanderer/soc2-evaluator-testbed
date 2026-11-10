using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ModernApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    public record LoginRequest(string Username, string Password);

    [HttpPost("login")]
    [AllowAnonymous]
    public IActionResult Login([FromBody] LoginRequest request)
    {
        // Minimal simulated login for Ledgerly portal
        if (request.Username == "admin" && request.Password == "password123")
        {
            return Ok(new { token = "synthetic-jwt-sample-token", username = request.Username });
        }

        return Unauthorized("Invalid credentials.");
    }
}
