namespace Errors;

public class UnexpectedArg: Exception {
	public UnexpectedArg(string arg)
	: base($"unexpected argument `{arg}`") { }
}

public class PathLeavesDir: Exception {
	internal PathLeavesDir(string dir, string path)
	: base($"path `{path}` leaves the installation directory {dir}") { }
}
