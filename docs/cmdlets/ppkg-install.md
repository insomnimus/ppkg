---
external help file: ppkg-help.xml
Module Name: ppkg
online version:
schema: 2.0.0
---

# ppkg-install

## SYNOPSIS
Downloads and installs a package.

## SYNTAX

```
ppkg-install [-package] <String[]> [-repo <String>] [-arch <Arch>] [-keepLogs] [<CommonParameters>]
```

## DESCRIPTION
The `ppkg-install` cmdlet downloads and installs a package on your system.

The `package` parameter is the name of a package that must exist in an installed repository.

The packages are installed in `$PPKG_ROOT/apps/<repo>/<app>/<version>` and the binaries are made available in `$PPKG_ROOT/bin`.
For the binaries to be available for other programs such as Powershell to access without specifying full paths, you must ensure that `$PPKG_ROOT/bin` is in the `$PATH` environment variable.

To update packages, see `ppkg-update`.
To uninstall packages, see `ppkg-remove`.

This cmdlet installs only the version that's currently known in an installed repository.
It might be desireable to run `ppkg-update` with no parameters beforehand to update the local repositories.

As with other package management cmdlets, `ppkg-install` uses filesystem transactions.

## EXAMPLES

### Example 1: Install the ffmpeg package
```powershell
PS> ppkg-install ffmpeg
```

### Example 2: install multiple packages in one command
```powershell
PS> ppkg-install go python
```

### Example 3: Install a package from a specific repository
```powershell
PS> ppkg-install -repo system-tools ripgrep
```

## PARAMETERS

### -arch
The architecture to install for

```yaml
Type: Arch
Parameter Sets: (All)
Aliases:
Accepted values: X32, X64

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -keepLogs
Do not remove the download log file on success

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -package
Name of the packages to install

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -repo
Specify a repository

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String[]

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
