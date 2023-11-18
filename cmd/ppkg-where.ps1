function :ppkg-where {
	[CmdletBinding()]
	[OutputType([string])]
	param (
		[Parameter(
			Mandatory, Position = 0,
			ValueFromPipeline, ValueFromRemainingArguments,
			HelpMessage = "The name of a shim"
		)]
		[string[]] $shim
	)

	begin {
		$ErrorActionPreference = "stop"
		$snippet = @'
[DllImport("shell32.dll", SetLastError = true)]
static extern IntPtr CommandLineToArgvW(
	[MarshalAs(UnmanagedType.LPWStr)] string lpCmdLine,
	out int pNumArgs
);

public static string[] CommandLineToArgs(string commandLine) {
	int argc;
	var argv = CommandLineToArgvW(commandLine, out argc);
	if (argv == IntPtr.Zero) throw new System.ComponentModel.Win32Exception();

	try {
		var args = new string[argc];
		for (var i = 0; i < args.Length; i++) {
			var p = Marshal.ReadIntPtr(argv, i * IntPtr.Size);
			args[i] = Marshal.PtrToStringUni(p);
		}
		return args;
	} finally {
		Marshal.FreeHGlobal(argv);
	}
}
'@

		# $StrToArgv = Add-Type -MemberDefinition $snippet -Name "StrToArgv" -Namespace PPKG.WinapiFunctions -PassThru
	}

	process {
		foreach($s in $shim) {
			if($s -notlike "*.exe") {
				$s = "$s.exe"
			}
			$p = join-path $script:settings.bin $s
			if(test-path -lp $p -type leaf) {
				$out = cmdc -i $p 2>&1
				if($LastExitCode -ne 0) {
					write-error "${s}: not a known shim"
				} elseif($out -match '^"(?<path>[^"]+)"') {
					# $path, $_argv = $StrToArgv::CommandLineToArgs($out)
					$matches.path
				} else {
					$out
				}
			} else {
				write-error "${s}: not found"
			}
		}
	}
}

function ppkg-where {
	[CmdletBinding()]
	[OutputType([string])]
	param (
		[Parameter(
			Mandatory, Position = 0,
			ValueFromPipeline, ValueFromRemainingArguments,
			HelpMessage = "The name of a shim"
		)]
		[string[]] $shim
	)

	try {
		script::ppkg-where -ea stop @PSBoundParameters
	} catch {
		write-error "error: $_"
	}
}
