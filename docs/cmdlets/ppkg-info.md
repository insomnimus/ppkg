---
external help file: ppkg-help.xml
Module Name: ppkg
online version:
schema: 2.0.0
---

# ppkg-info

## SYNOPSIS
Displays information about an app.

## SYNTAX

```
ppkg-info [-package] <String> [-repo <String>] [<CommonParameters>]
```

## DESCRIPTION
The `ppkg-info` cmdlet displays information about a package.

## EXAMPLES

### Example 1: Display information about a package
```powershell
PS> ppkg-info aria2
```

## PARAMETERS

### -package
Name of the package

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -repo
The repository the package should be searched in

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

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
