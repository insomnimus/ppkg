namespace Action;

using System;
using CommandLine;

public interface Command {
	string Name { get; }
	void Run(Context ctx);
}

public class Action {
	public Command Cmd { get; set; }

	public Action(Command cmd) => this.Cmd = cmd;

	public void Run(Context ctx) => this.Cmd.Run(ctx);

	public static Action? NewAction(string name, string[] args, out IEnumerable<Error>? errors) {
		IEnumerable<Error>? errs = null;
		var settings = new ParserSettings() {
			AutoHelp = false,
			AutoVersion = false,
			CaseSensitive = true,
			CaseInsensitiveEnumValues = true,
			EnableDashDash = true,
			IgnoreUnknownArguments = false,
		};
		var parser = new Parser(s => s = settings);

		Func<IEnumerable<Error>, Command?> err = (e) => {
			errs = e;
			return null;
		};
		Func<Command?, Command?> ok = x => x;

		var c = name switch {
			"copy" => parser.ParseArguments<Copy>(args).MapResult(ok, err),
			"create" => parser.ParseArguments<Create>(args).MapResult(ok, err),
			"link" => parser.ParseArguments<Link>(args).MapResult(ok, err),
			"move" => parser.ParseArguments<Move>(args).MapResult(ok, err),
			"remove" => parser.ParseArguments<Remove>(args).MapResult(ok, err),
			_ => throw new Exception("not handled"),
		};

		errors = errs;
		if (c != null) return new Action(c!);
		else return null;
	}
}
