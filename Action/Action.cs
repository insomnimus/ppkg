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

	public Action(string name, string[] args) {
		var settings = new ParserSettings() {
			AutoHelp = false,
			AutoVersion = false,
			CaseSensitive = true,
			CaseInsensitiveEnumValues = true,
			EnableDashDash = true,
			IgnoreUnknownArguments = false,
		};
		var parser = new Parser(s => s = settings);

		Func<IEnumerable<Error>, Command> err = (e) => {
			throw new ActionParseError(name, args, e.First());
		};
		Func<Command, Command> ok = x => x;

		this.Cmd = name switch {
			"copy" => parser.ParseArguments<Copy>(args).MapResult(ok, err),
			"create" => parser.ParseArguments<Create>(args).MapResult(ok, err),
			"link" => parser.ParseArguments<Link>(args).MapResult(ok, err),
			"mkdir" => parser.ParseArguments<Mkdir>(args).MapResult(ok, err),
			"move" => parser.ParseArguments<Move>(args).MapResult(ok, err),
			"remove" => parser.ParseArguments<Remove>(args).MapResult(ok, err),
			_ => throw new UnknownActionError(name),
		};
	}
}
