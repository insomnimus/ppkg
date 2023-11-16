namespace Action;

using System;
using CommandLine;

public class Move: Command {
	public string Name => "move";

	[Option('f', "force")]
	public bool Force { get; set; }

	[Value(0, Min = 2)]
	public IEnumerable<string> Files { get; set; }

	public void Run(Context ctx) {
		throw new NotImplementedException();
	}
}
