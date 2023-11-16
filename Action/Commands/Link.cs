namespace Action;

using CommandLine;

public class Link: Command {
	public string Name => "link";

	[Option('f', "force")]
	public bool Force { get; set; }
	[Option('h', "hard", SetName = "hard")]
	public bool Hard { get; set; }
	[Option('j', "junction", SetName = "junction")]
	public bool Junction { get; set; }
	[Option('s', "soft", SetName = "soft")]
	public bool Soft { get; set; }

	[Value(0, Required = true)]
	public string Path { get; set; }
	[Value(1, Required = true)]
	public string PointsTo { get; set; }

	[Value(2)]
	public string? __stop {
		get => null;
		set { throw new Errors.UnexpectedArg(value!); }
	}

	public void Run(Context ctx) {
		throw new NotImplementedException();
	}
}
