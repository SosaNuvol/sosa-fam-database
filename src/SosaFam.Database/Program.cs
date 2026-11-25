using System.Diagnostics;
using System.Reflection;
using System.Text.RegularExpressions;
using Microsoft.Data.SqlClient;

// Migration runner for sosa-fam-database.
//
// Runs the migrations in Migrations/ (embedded in this build) in file-name order and skips
// every migration already recorded in [dbo].[SchemaVersion] with Success = 1. Each migration
// owns its transaction, checks SchemaVersion and records itself (see Migrations/_TEMPLATE_Migration.sql).
// The five baseline scripts (00000000_0001 to 0005) predate that format: the runner wraps each
// in a transaction and records it.
//
// Usage:
//   dotnet run --project src/SosaFam.Database -- [options] "<connection string>"
//   (or pass --connection-stdin and write the connection string as the first line of standard
//   input, which is how the deploy scripts pass a password; or set SOSAFAM_DB_CONNECTION, for Dev)
//
// Options:
//   --what-if             list what would run; change nothing
//   --filter <name>       run only this migration (exact name, or a prefix ending in *); repeatable
//   --require <name>      stop unless this migration is already applied; repeatable
//   --ensure-database     create the database if it does not exist (Dev only)
//   --list                list every migration and whether it is applied
//   --connection-stdin    read the connection string from the first line of standard input

var options = Options.Parse(args);
if (options is null) return 2;

var all = LoadMigrations();
var selected = all.Where(m => options.Filters.Count == 0 || options.Filters.Any(f => Matches(m.Name, f))).ToList();
if (options.Filters.Count > 0 && selected.Count == 0)
{
    Console.Error.WriteLine("No migration matches the filter.");
    return 2;
}

var builder = new SqlConnectionStringBuilder(options.ConnectionString);
Console.WriteLine($"Target: {builder.DataSource} / {builder.InitialCatalog}{(options.WhatIf ? "  (what-if: nothing will change)" : "")}");

if (options.EnsureDatabase && !options.WhatIf) EnsureDatabase(builder);

await using var connection = new SqlConnection(options.ConnectionString);
connection.InfoMessage += (_, e) => Console.WriteLine($"    {e.Message}");
await connection.OpenAsync();

var applied = await AppliedAsync(connection);

var missing = options.Requires.Where(r => !applied.Contains(r)).ToList();
if (missing.Count > 0)
{
    Console.Error.WriteLine("Stopping: prerequisites are not applied:");
    foreach (var m in missing) Console.Error.WriteLine($"  {m}");
    return 3;
}

if (options.List)
{
    foreach (var m in all) Console.WriteLine($"  [{(applied.Contains(m.Name) ? "applied" : "pending")}] {m.Name}");
    return 0;
}

var pending = selected.Where(m => !applied.Contains(m.Name)).ToList();
foreach (var m in selected.Where(m => applied.Contains(m.Name))) Console.WriteLine($"  [skip] {m.Name} (already applied)");
if (pending.Count == 0)
{
    Console.WriteLine("Nothing to apply. Database is up to date.");
    return 0;
}

if (options.WhatIf)
{
    foreach (var m in pending) Console.WriteLine($"  [would run] {m.Name}");
    return 0;
}

var ran = 0;
foreach (var migration in pending)
{
    // A migration can record others (00000000_0000 records the DbUp baseline), so read again.
    applied = await AppliedAsync(connection);
    if (applied.Contains(migration.Name))
    {
        Console.WriteLine($"  [skip] {migration.Name} (recorded by an earlier migration)");
        continue;
    }

    Console.WriteLine($"  [run]  {migration.Name}");
    var watch = Stopwatch.StartNew();
    try
    {
        if (migration.IsBaseline)
        {
            await using var tx = (SqlTransaction)await connection.BeginTransactionAsync();
            foreach (var batch in migration.Batches) await ExecuteAsync(connection, batch, tx);
            await RecordAsync(connection, migration.Name, "Baseline script", watch.ElapsedMilliseconds, tx);
            await tx.CommitAsync();
        }
        else
        {
            foreach (var batch in migration.Batches) await ExecuteAsync(connection, batch, null);
            if (!(await AppliedAsync(connection)).Contains(migration.Name))
                throw new InvalidOperationException("The migration ran but did not record itself in [dbo].[SchemaVersion].");
        }
    }
    catch (Exception ex)
    {
        Console.ForegroundColor = ConsoleColor.Red;
        Console.Error.WriteLine($"  [FAILED] {migration.Name}: {ex.Message}");
        Console.Error.WriteLine("Stopped. Nothing after this migration ran.");
        Console.ResetColor();
        return 1;
    }
    ran++;
    Console.WriteLine($"  [ok]   {migration.Name} ({watch.ElapsedMilliseconds} ms)");
}

Console.ForegroundColor = ConsoleColor.Green;
Console.WriteLine($"Applied {ran} migration(s). Database is up to date.");
Console.ResetColor();
return 0;

static bool Matches(string name, string filter) =>
    filter.EndsWith('*') ? name.StartsWith(filter.TrimEnd('*'), StringComparison.OrdinalIgnoreCase)
                         : string.Equals(name, Path.GetFileNameWithoutExtension(filter), StringComparison.OrdinalIgnoreCase);

static List<Migration> LoadMigrations()
{
    var assembly = Assembly.GetExecutingAssembly();
    var go = new Regex(@"^\s*GO\s*(?:--.*)?$", RegexOptions.Multiline | RegexOptions.IgnoreCase);
    return assembly.GetManifestResourceNames()
        .Where(n => n.StartsWith("Migrations/") && n.EndsWith(".sql"))
        .Select(n =>
        {
            using var reader = new StreamReader(assembly.GetManifestResourceStream(n)!);
            var name = Path.GetFileNameWithoutExtension(n["Migrations/".Length..]);
            var batches = go.Split(reader.ReadToEnd()).Where(b => !string.IsNullOrWhiteSpace(b)).ToList();
            var isBaseline = Regex.IsMatch(name, @"^00000000_000[1-5]_Baseline_");
            return new Migration(name, batches, isBaseline);
        })
        .OrderBy(m => m.Name, StringComparer.Ordinal)
        .ToList();
}

static async Task<HashSet<string>> AppliedAsync(SqlConnection connection)
{
    var set = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
    await using var cmd = new SqlCommand(
        "IF OBJECT_ID(N'[dbo].[SchemaVersion]', N'U') IS NOT NULL " +
        "SELECT [MigrationName] FROM [dbo].[SchemaVersion] WHERE [Success] = 1;", connection);
    await using var reader = await cmd.ExecuteReaderAsync();
    while (await reader.ReadAsync()) set.Add(reader.GetString(0));
    return set;
}

static async Task ExecuteAsync(SqlConnection connection, string sql, SqlTransaction? tx)
{
    await using var cmd = new SqlCommand(sql, connection, tx) { CommandTimeout = 0 };
    await cmd.ExecuteNonQueryAsync();
}

static async Task RecordAsync(SqlConnection connection, string name, string description, long ms, SqlTransaction tx)
{
    await using var cmd = new SqlCommand(
        "INSERT INTO [dbo].[SchemaVersion] ([MigrationName], [Description], [Success], [ExecutionTimeMs]) VALUES (@Name, @Description, 1, @Ms);",
        connection, tx);
    cmd.Parameters.AddWithValue("@Name", name);
    cmd.Parameters.AddWithValue("@Description", description);
    cmd.Parameters.AddWithValue("@Ms", (int)ms);
    await cmd.ExecuteNonQueryAsync();
}

static void EnsureDatabase(SqlConnectionStringBuilder target)
{
    var master = new SqlConnectionStringBuilder(target.ConnectionString) { InitialCatalog = "master" };
    using var connection = new SqlConnection(master.ConnectionString);
    connection.Open();
    using var cmd = new SqlCommand("IF DB_ID(@Name) IS NULL BEGIN DECLARE @Sql NVARCHAR(400) = N'CREATE DATABASE ' + QUOTENAME(@Name); EXEC sp_executesql @Sql; END", connection);
    cmd.Parameters.AddWithValue("@Name", target.InitialCatalog);
    cmd.ExecuteNonQuery();
}

record Migration(string Name, IReadOnlyList<string> Batches, bool IsBaseline);

record Options(string ConnectionString, bool WhatIf, bool EnsureDatabase, bool List, List<string> Filters, List<string> Requires)
{
    public static Options? Parse(string[] args)
    {
        var filters = new List<string>();
        var requires = new List<string>();
        bool whatIf = false, ensure = false, list = false, fromStdin = false;
        string? connection = null;
        for (var i = 0; i < args.Length; i++)
        {
            switch (args[i])
            {
                case "--what-if": whatIf = true; break;
                case "--ensure-database": ensure = true; break;
                case "--list": list = true; break;
                case "--connection-stdin": fromStdin = true; break;
                case "--filter" when i + 1 < args.Length: filters.Add(args[++i]); break;
                case "--require" when i + 1 < args.Length: requires.Add(args[++i]); break;
                default:
                    if (args[i].StartsWith("--")) { Console.Error.WriteLine($"Unknown option {args[i]}"); return null; }
                    connection = args[i];
                    break;
            }
        }
        if (fromStdin)
        {
            if (connection is not null) { Console.Error.WriteLine("Use --connection-stdin or a connection string argument, not both."); return null; }
            // Read as UTF-8 whatever the console code page is. Windows PowerShell 5.1 can prefix
            // piped text with a byte-order mark: the reader drops a BOM it recognizes, and a
            // stray U+FEFF left by a re-encoding is trimmed too.
            using var stdin = new StreamReader(Console.OpenStandardInput(), new System.Text.UTF8Encoding(false), detectEncodingFromByteOrderMarks: true);
            connection = stdin.ReadLine()?.TrimStart('\uFEFF').Trim();
        }
        connection ??= Environment.GetEnvironmentVariable("SOSAFAM_DB_CONNECTION");
        if (string.IsNullOrWhiteSpace(connection))
        {
            Console.Error.WriteLine("Pass a connection string, pass --connection-stdin, or set SOSAFAM_DB_CONNECTION.");
            return null;
        }
        return new Options(connection, whatIf, ensure, list, filters, requires);
    }
}
