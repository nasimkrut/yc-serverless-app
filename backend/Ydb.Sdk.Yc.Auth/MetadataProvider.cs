using System.Text.Json;
using Microsoft.Extensions.Logging;
using Ydb.Sdk.Auth;

namespace Ydb.Sdk.Yc;

// Ydb.Sdk loads this class via reflection when EnableMetadataCredentials = true.
// It expects: assembly "Ydb.Sdk.Yc.Auth", class "Ydb.Sdk.Yc.Auth.MetadataProvider",
// constructor (ILoggerFactory), implements ICredentialsProvider.
public class MetadataProvider : ICredentialsProvider
{
    private static readonly HttpClient Http = new() { Timeout = TimeSpan.FromSeconds(5) };

    static MetadataProvider()
    {
        Http.DefaultRequestHeaders.Add("Metadata-Flavor", "Google");
    }

    public MetadataProvider(ILoggerFactory? loggerFactory = null) { }

    public async ValueTask<string> GetAuthInfoAsync()
    {
        try
        {
            var json = await Http.GetStringAsync(
                "http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/token");
            return JsonDocument.Parse(json).RootElement
                .GetProperty("access_token").GetString() ?? "";
        }
        catch
        {
            return "";
        }
    }
}
