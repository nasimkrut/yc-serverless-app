using System.Data;
using Ydb.Sdk.Ado;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddCors(options =>
    options.AddDefaultPolicy(policy =>
        policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader()));

var app = builder.Build();
app.UseCors();

var instanceId = Guid.NewGuid().ToString("N")[..8];
const string BackendVersion = "v1.0.0";

var ydbEndpoint = Environment.GetEnvironmentVariable("YDB_ENDPOINT");
var ydbDatabase = Environment.GetEnvironmentVariable("YDB_DATABASE");

YdbDataSource? db = null;

if (!string.IsNullOrEmpty(ydbEndpoint) && !string.IsNullOrEmpty(ydbDatabase))
{
    var uri = new Uri(ydbEndpoint);
    var csb = new YdbConnectionStringBuilder
    {
        Host = uri.Host,
        Port = uri.Port,
        Database = ydbDatabase,
        UseTls = ydbEndpoint.StartsWith("grpcs://"),
        EnableMetadataCredentials = true
    };
    db = new YdbDataSourceBuilder(csb).Build();
}

app.MapGet("/api/version", () =>
    Results.Ok(new { version = BackendVersion, instance = instanceId }));

app.MapGet("/api/messages", async () =>
{
    if (db is null)
        return Results.Ok(Array.Empty<object>());

    var messages = new List<object>();
    await using var conn = await db.OpenConnectionAsync();
    await using var cmd = conn.CreateCommand();
    cmd.CommandText = "SELECT id, text, created_at FROM messages ORDER BY created_at DESC LIMIT 50;";
    await using var reader = await cmd.ExecuteReaderAsync();
    while (await reader.ReadAsync())
        messages.Add(new
        {
            id = reader.GetString(0),
            text = reader.GetString(1),
            createdAt = reader.GetDateTime(2).ToString("O")
        });

    return Results.Ok(messages);
});

app.MapPost("/api/messages", async (MessageDto dto) =>
{
    if (string.IsNullOrWhiteSpace(dto.Text))
        return Results.BadRequest(new { error = "Text is required" });
    if (db is null)
        return Results.StatusCode(503);

    var id = Guid.NewGuid().ToString();
    await using var conn = await db.OpenConnectionAsync();
    await using var cmd = conn.CreateCommand();
    cmd.CommandText = """
        DECLARE $id AS Utf8;
        DECLARE $text AS Utf8;
        DECLARE $created_at AS Timestamp;
        INSERT INTO messages (id, text, created_at) VALUES ($id, $text, $created_at);
        """;
    cmd.Parameters.Add(new YdbParameter("$id", DbType.String, id));
    cmd.Parameters.Add(new YdbParameter("$text", DbType.String, dto.Text));
    cmd.Parameters.Add(new YdbParameter("$created_at", DbType.DateTime, DateTime.UtcNow));
    await cmd.ExecuteNonQueryAsync();

    return Results.Ok(new { id });
});

app.Run();

record MessageDto(string Text);
