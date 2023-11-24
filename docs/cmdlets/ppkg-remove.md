---
external help file: ppkg-help.xml
Module Name: ppkg
online version:
schema: 2.0.0
---

# ppkg-remove

## SYNOPSIS
Uninstalls a previously installed package or packages.

## SYNTAX

### literal (Default)
```
ppkg-remove [-glob] [-yes] [-full] [<CommonParameters>]
```

### noglob
```
ppkg-remove [-package] <String[]> [-glob] [-yes] [-full] [<CommonParameters>]
```

## DESCRIPTION
The `ppkg-remove` cmdlet uninstalls packages specified on the command line.

You can uninstall packages that match a wildcard pattern by specifying the `-glob` flag.

By default `ppkg-remove` does "soft" uninstallation:
- The Binary shims are removed from the bin directory;
- The installation record is removed;
- However, the package contents are kept in cache in case of future reinstallations.

By specifying the `-full` flag, you can force ppkg to remove the package contents from the caches as well.

The persisted files and folders of the removed packages are never removed.

If a binary of a removed package is currently running, this command will abort the operation and throw an error.
In these cases, the running program must be terminated.

As with other package management cmdlets, `ppkg-remove` uses filesystem transactions.

## EXAMPLES

### Example 1: Remove a package
```powershell
PS> ppkg-remove php
```

### Example 2: Remove multiple packages
```powershell
PS> ppkg-remove python node
```

### Example 3: Remove packages that match a pattern
```powershell
PS> ppkg-remove ffmpeg* -glob
```

## PARAMETERS

### -full
Do not leave behind existing files for caching

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

### -glob
Uninstall packages matching the pattern

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
Names of packages to uninstall

```yaml
Type: String[]
Parameter Sets: noglob
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -yes
Do not prompt for confirmation

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String[]

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
