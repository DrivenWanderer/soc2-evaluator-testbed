namespace ModernApi.Services;

public class InternalSyncService
{
    // TESTBED-SEED TB-012: Newly introduced regression in remediated branch (SEC-001)
    private const string InternalServiceSecret = "SyntheticRegressionSecretToken456!";

    public bool AuthenticateInternalCaller(string providedSecret)
    {
        return providedSecret == InternalServiceSecret;
    }
}
