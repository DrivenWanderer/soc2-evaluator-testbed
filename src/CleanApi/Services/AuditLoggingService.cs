namespace CleanApi.Services;

public interface IAuditLoggingService
{
    void LogAuthenticationSuccess(string username, string ipAddress);
    void LogAuthenticationFailure(string username, string ipAddress, string reason);
}

public class AuditLoggingService : IAuditLoggingService
{
    private readonly ILogger<AuditLoggingService> _logger;

    public AuditLoggingService(ILogger<AuditLoggingService> logger)
    {
        _logger = logger;
    }

    public void LogAuthenticationSuccess(string username, string ipAddress)
    {
        _logger.LogInformation("AUTH_AUDIT_SUCCESS: User '{Username}' successfully authenticated from '{IpAddress}' at {TimestampUtc}",
            username, ipAddress, DateTimeOffset.UtcNow);
    }

    public void LogAuthenticationFailure(string username, string ipAddress, string reason)
    {
        _logger.LogWarning("AUTH_AUDIT_FAILURE: User '{Username}' failed authentication from '{IpAddress}'. Reason: '{Reason}' at {TimestampUtc}",
            username, ipAddress, reason, DateTimeOffset.UtcNow);
    }
}
