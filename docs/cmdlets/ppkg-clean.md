---
external help file: ppkg-help.xml
Module Name: ppkg
online version:
schema: 2.0.0
---

# ppkg-clean

## SYNOPSIS
Cleans up unneeded packages and files.

## SYNTAX

```
ppkg-clean [[-package] <String[]>] [-repo <String[]>] [-full] [-keepTemporary] [-logs] [<CommonParameters>]
```

## DESCRIPTION
The `ppkg-clean` cmdlet cleans up files that are not in use.
This is a safe operation; no installed app is removed.

PPKG does not remove older versions of the apps from the filesystem upon update or remove (unless the -full flag is used with `ppkg-remove`).
These caches are reused upon reinstallation.

This command by default:
- Removes all but the currently installed version and the latest other cached version of an app;
- Removes all but the latest version of an app that was previously uninstalled without the `-full` flag;
- Removes the temporary files and folders.

If the `-full` flag is specified:
- Removes all but the currently installed version of apps;
- Removes all cached versions of previously uninstalled apps;
- Removes the temporary files and folders.

You can keep the temporary files using the `-noTemporary` flag.

The logs are not removed. To remove the logs as weell, specify the `-logs` flag.

## EXAMPLES

### Example 1: Do a cache-friendly system cleanup
```powershell
PS> ppkg-clean
```

## PARAMETERS

### -full
Do not leave the latest version in the cache

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

### -keepTemporary
Do not remove temporary files

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

### -logs
Remove log files

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
Packages to clean (accepts glob)

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -repo
Clean packages in the provided repositories only

```yaml
Type: String[]
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
