function :ppkg-add-repo {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, Position = 0, HelpMessage = "The name that will be used locally to refer to the repository")]
		[string] $name,
		[Parameter(Mandatory, Position = 1, HelpMessage = "The git clone URL of the repository")]
		[string] $git
	)

	$ErrorActionPreference = "stop"

	$path = join-path $script:settings.repos $name
	if($f = script::get-file $path -ea ignore) {
		if($f.IsDirectory) {
			write-error "a repository with the same name is already installed"
		} else {
			write-error "the file $path already exists"
		}
	}

	if(-not (get-command git.exe -ea ignore)) {
		write-error "failed to locate a git executable to clone with"
	}

	git clone $git $path
	assert-ok "git clone exited with $LastExitCode"
	info "added new repository ``$name``"
}

function ppkg-add-repo {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, Position = 0, HelpMessage = "The name that will be used locally to refer to the repository")]
		[ValidateNotNullOrEmpty()]
		[ValidateScript({
				if($_ -like "*[:/\]*") {
					throw "the repository name cannot contain path separators"
				}

				$invalid = [System.Collections.Generic.HashSet[char]] [IO.Path]::GetInvalidFileNameChars()
				$null = '[ ]`;$@^'.GetEnumerator() | foreach-object { $invalid.add($_) }
				foreach($c in "$_".GetEnumerator()) {
					if($invalid.contains($c)) {
						throw "the repository name cannot contain the character '$c'"
					}

					$true
				}
			})]
		[string] $name,
		[Parameter(Mandatory, Position = 1, HelpMessage = "The git clone URL of the repository")]
		[string] $git
	)

	try {
		script::ppkg-add-repo -ea stop @PSBoundParameters
	} catch {
		err -log "$_"
	}
}
