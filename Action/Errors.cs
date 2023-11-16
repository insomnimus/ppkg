namespace Action;

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

public class ActionParseError: Exception {
	public string Name { get; init; }
	public string[] Args { get; init; }
	public string Error { get; init; }

	internal ActionParseError(string name, string[] args, CommandLine.Error error)
	: base($"failed to parse command {name}: {error}") {
		this.Name = name;
		this.Args = args;
		this.Error = error.ToString();
	}

	internal ActionParseError(string name, string[] args, string error)
: base($"failed to parse command {name}: {error}") {
		this.Name = name;
		this.Args = args;
		this.Error = error;
	}
}
