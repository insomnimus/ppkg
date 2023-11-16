namespace Action;

using CommandLine;

public class Create: Command {
	public string Name => "create";

	[Option('f', "force")]
	public bool Force { get; set; }

	[Option('d', "data")]
	public string? Data { get; set; }

	[Value(0, Min = 1)]
	public IEnumerable<string> Path { get; set; }

	public void Run(Context ctx) {
		throw new NotImplementedException();
	}
}
