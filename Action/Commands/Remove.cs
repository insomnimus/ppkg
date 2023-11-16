namespace Action;

using CommandLine;

public class Remove: Command {
	public string Name => "remove";

	[Option('f', "force")]
	public bool Force { get; set; }
	[Option('r', "recurse")]
	public bool Recurse { get; set; }

	[Value(0, Min = 1)]
	public IEnumerable<string> Files { get; set; }

	public void Run(Context ctx) {
		throw new NotImplementedException();
	}
}
