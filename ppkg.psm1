$ErrorActionPreference = "stop"
new-variable is64 ([Environment]::Is64BitOperatingSystem) -scope private -option constant

$settings = [Settings] @{}
# Create directories if they're missing
$null = new-item -ea ignore -type directory -path $settings.installed, $settings.root, $settings.tmp, $settings.bin, $settings.apps, $settings.repos, $settings.logs, $settings.persist

class Settings {
	[string] $root
	[string] $sshConfig

	# These are overwritten to be read-only getters
	[string] $installed
	[string] $tmp
	[string] $apps
	[string] $repos
	[string] $bin
	[string] $logs
	[string] $persist

	# This is how you implement get/set attributes in powershell.
	# It's a little hacky but it works just fine.
	hidden $__init__ = {
		# We don't want setters in this case so the only script block {} is for the getter.
		$this | add-member ScriptProperty installed { join-path $this.root installed } -TypeName string -force
		$this | add-member ScriptProperty tmp { join-path $this.root tmp } -TypeName string -force
		$this | add-member ScriptProperty repos { join-path $this.root repositories } -TypeName string -force
		$this | add-member ScriptProperty apps { join-path $this.root apps } -TypeName string -force
		$this | add-member ScriptProperty bin { join-path $this.root bin } -TypeName string -force
		$this | add-member ScriptProperty logs { join-path $this.root logs } -TypeName string -force
		$this | add-member ScriptProperty persist { join-path $this.root persist } -TypeName string -force
	}.invoke()

	Settings() {
		$r = if($env:PPKG_ROOT) {
			$env:PPKG_ROOT
		} else {
			join-path $env:SYSTEMDRIVE ppkg
		}

		$this.root = $r
		$conf = join-path $r ppkg.json
		if(test-path -type leaf -lp $conf) {
			try {
				$j = get-content -raw -lp $conf | ConvertFrom-Json -depth 10
				$this.sshConfig = $j | foreach-object sshConfig
			} catch {
				script:warn "failed to load ppkg configuration from ${conf}: $_"
			}
		}
	}

	# Returns the path of a bundled executable (internal use)
	[string] exec([string] $name) {
		if(!$name.EndsWith(".exe")) {
			$name += ".exe"
		}
		$paths = @(
			join-path $PSScriptRoot libexec $name
			join-path $env:SystemRoot system32 $name
			get-command -CommandType Application $name -ea ignore | select-object -First 1 -ExpandProperty Path
		)

		foreach($path in $paths) {
			if(test-path -lp $path) {
				return $path
			}
		}

		throw "could not locate a $name executable"
	}

	[Repo[]] GetRepos([string[]] $name) {
		$r = get-childitem -directory -lp $this.repos -force -ea stop `
		| where-object { $name.count -eq 0 -or $_.name -cin $name } `
		| foreach-object {
			# Check if it's a git repo by executing a git command.
			# Checking for existence of the .git directory is unreliable.
			$null = git -C $_ rev-parse
			if($LastExitCode -eq 0) {
				[GitRepo] @{ name = $_.name }
			} else {
				[Repo] @{ name = $_.name }
			}
		}

		return $r
	}
}

class Repo {
	[string] $name
	[string] $uri

	[string] LocalPath() {
		return (join-path $script:settings.repos $this.name)
	}

	[bool] Update() {
		return $false
	}

	[string] ToString() {
		return $this.name
	}
}

class GitRepo: Repo {
	[bool] Update() {
		$path = $this.LocalPath()
		git -C $path clean -qfxd
		assert-ok "git clean exited with $lastExitCode"
		git -C $path reset --hard HEAD -q
		assert-ok "git reset exited with $lastExitCode"

		$oldHash = git -C $path rev-parse HEAD
		git -C $path pull -fq
		assert-ok "git pull exited with $lastExitCode"
		$newHash = git -C $path rev-parse HEAD

		return ($oldHash -ne $newHash)
	}

	[string] ToString() {
		return "$($this.name) (git)"
	}
}
