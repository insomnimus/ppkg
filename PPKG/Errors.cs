namespace PPKG;

public class PathLeavesDirError: Exception {
	public string Dir { get; init; }
	public string Path { get; init; }

	internal PathLeavesDirError(string dir, string path)
	: base($"path `{path}` leaves the installation directory {dir}") {
		this.Dir = dir;
		this.Path = path;
	}
}

public class Unreachable: Exception {
	internal Unreachable() : base("(internal bug) unreachable branch was reached") { }
	internal Unreachable(string msg) : base($"(internal bug) unreachable branch was reached: {msg}") { }
}

public class UnknownActionError: Exception {
	public string Name { get; init; }

	internal UnknownActionError(string name)
	: base($"unknown action `{name}`") {
		this.Name = name;
	}
}

public class ActionArgError: Exception {
	public string Name { get; init; }
	public string[] Args { get; init; }
	public string Error { get; init; }

	internal ActionArgError(string name, string[] args, CommandLine.Error error)
	: base($"failed to parse command {name}: {error}") {
		this.Name = name;
		this.Args = args;
		this.Error = error.ToString();
	}

	internal ActionArgError(string name, string[] args, string error)
: base($"failed to parse command {name}: {error}") {
		this.Name = name;
		this.Args = args;
		this.Error = error;
	}
}

public class ActionParseError: FormatException {
	internal long pos;
	internal string input;

	public override string Message => this.message();

	internal ActionParseError(string input, long pos) {
		this.pos = pos;
		this.input = input;
	}

	private string message() {
		var line = 1;
		var start = 0;

		for (var i = 0; i < this.pos; i++) {
			if (this.input[i] == '\n') {
				start = i;
				line++;
			}
		}

		var s = this.input.Substring(start);
		var len = s.IndexOf('\n');
		s = (len < 0) ? s : s.Substring(0, len);

		var col = (start == 0)
		? 1
		: (1 + this.pos % start);

		return $"{line}:{col}: unterminated quote\nline: {s}";
	}
}
