using System.Reflection;
using DbUp;

// Applies the numbered scripts in Scripts/ that have not run yet, in order.
// Each script runs once; the record of applied scripts lives in dbo.SchemaVersions.
//
// Usage:
//   dotnet run --project src/SosaFam.Database -- "<connection string>"
// or set SOSAFAM_DB_CONNECTION and run with no arguments.
//   --ensure-database  create the database first if it does not exist (dev only)

var ensureDatabase = args.Contains("--ensure-database");
var connectionString = args.FirstOrDefault(a => !a.StartsWith("--"))
    ?? Environment.GetEnvironmentVariable("SOSAFAM_DB_CONNECTION");

if (string.IsNullOrWhiteSpace(connectionString))
{
    Console.Error.WriteLine("Pass a connection string or set SOSAFAM_DB_CONNECTION.");
    return 2;
}

if (ensureDatabase)
{
    EnsureDatabase.For.SqlDatabase(connectionString);
}

var upgrader = DeployChanges.To
    .SqlDatabase(connectionString)
    .WithScriptsEmbeddedInAssembly(Assembly.GetExecutingAssembly())
    .WithTransactionPerScript()
    .LogToConsole()
    .Build();

var result = upgrader.PerformUpgrade();

if (!result.Successful)
{
    Console.ForegroundColor = ConsoleColor.Red;
    Console.Error.WriteLine(result.Error);
    Console.ResetColor();
    return 1;
}

Console.ForegroundColor = ConsoleColor.Green;
Console.WriteLine("Database is up to date.");
Console.ResetColor();
return 0;
