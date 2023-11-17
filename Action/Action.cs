namespace PPKG;

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
			throw new ActionArgError(name, args, e.First());
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

	public static Action Parse(string command) {
		var words = ShellWords.Parse(command);
		if (words.Length == 0) {
			throw new ArgumentException("the input string is empty or only contains whitespace", "command");
		}
		return new Action(words[0], words[1..]);
	}
}
