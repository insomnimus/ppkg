# Actions
An action is a safe command you can use to perform actions during installation steps.

Actions can only reference, read or modify the installation directory; they cannot read, write or point to other directories in the users filesystem.
Therefore ensuring safe execution.

All actions are transactional; meaning, on an error every prior filesystem operation including related package install or update, will safely be rolled back.

## Syntax
An action in a package manifest is a single command string in a syntax similar to Powershell or Bash.

An action is simply a command name and arguments separated by whitespace.
You can quote arguments to include whitespace in them using single or double quotes.
You can escape characters with the Powershell escape character `````.
Escapes in a single quote quoted strings are treated literally; no escaping is done.
Otherwise, some escape patterns are recognized:
- ```0``: A null byte.
- ```a``: Anchor.
- ```b``: Backspace.
- ```f``: Form feed.
- ```n``: Line feed (lf; new line).
- ```r``: Carriage return (cr).
- ```t``: Horizontal tab.
- ```v``: Vertical tab.
- Any other escape: the character itself; the escape character is omitted.

### Examples
```json
{
	"version": "0.1.0",
	"description": "...",
	"license": "...",
	"bin": ["..."],
	"x32": {
		"url": "...",
		"preInstall": [
			"mkdir config",
			"create config/user.conf --data '[user]' --encoding utf8"
		]
	}
}
```

## Available Commands
### copy
Copies files and folders.

Options:
- `-f, --force`: Overwrite files if they exist.
- `-n, --null-glob`: If a glob pattern matches no file, discard it.

Args:
- 2 or more paths, last one being the target.

If the destination exists and is a directory, files will be copied into it.
If the destination does not exist or is not a directory, and more than 1 file is specified, this command throws an error.
Unlike the `Copy-Item` cmdlet or the Linux `cp` command, this action always copies directories recursively.

### create
Creates files, optionally fills them with content.

Options:
- `-f, --force`: Overwrite existing files.
- `-m, --if-missing`: Ignore files that already exist.
- `-e, --encoding=ascii|utf7|utf8|utf16|utf16be|utf32`: The text encoding to write with. Default is `utf8`.

Arguments:
- One or more files.

### link
Creates hard links or directory junctions.

Options:
- `-f, --force`: Overwrite files if they exist.
- `-h, --hard`: Create a hard link.
- `-j, --junction`: Create a directory junction.

Arguments:
- `<path>`: The path of the file that will be created.
- `<pointsTo>`: The path the link will point to.

If the `--hard` flag is specified, the `pointsTo` argument must point to an existing file.
If the `--junction` flag is specified, the `pointsTo` argument must point to an existing directory.
If neither `--hard` nor `--junction` is specified, the type of link will be inferred from the `pointsTo>` argument:
- If it's a directory, a junction will be created.
- If it's a file, a hard link will be created.

### mkdir
Creates directories.

Arguments:
- One or more paths.

The `mkdir` action creates directories.
Existing directories will not be overwritten and silently ignored.
This action will create all the parent directories necessary similar to the `-p` flag in the Linux `mkdir` command.

### move
Moves (renames) files or folders.

Options:
- `-f, --force`: Overwrite files if they already exist.
- `-n, --null-glob`: Ignore glob patterns that don't match any file.

Arguments:
- 2 or more paths.

The last path will be considered the destination.
Similar to the [copy action](#copy), if the destination already exists and is a directory, files will be moved into it.
If destination does not exist or is not a directory, and more than one source path is provided, this action will throw an error.

The source path arguments can be glob patterns.

### remove
Removes files and directories.

Options:
- `-n, --null-glob`: Ignore glob patterns that match no paths.

Arguments:
- One or more paths / glob patterns.

Unlike the `Remove-Item` cmdlet in Powershell or the Linux `rm` command, directories are always removed recursively.

## Glob Patterns
Some actions will evaluate glob patterns using the [Dotnet.Glob package](https://github.com/dazinator/DotNet.Glob).
Glob matching is case insensitive just like Windows filesystems.
If a glob pattern does not match any path, by default it is used literally as a path.
To prevent this, use the `--null-glob` flag.

## Execution
The paths passed to any action are relative to the installation directory, which is left unspecified.
Paths cannot leave the installation directory in any way; if a path is outside the installation directory, an error will be thrown.
All actions are transactional. This means that any modification will be rolled back on error, along with the related package install or update.
In other words, actions will never leave the installation directory in an unexpected state.
