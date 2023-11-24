---
external help file: ppkg-help.xml
Module Name: ppkg
online version:
schema: 2.0.0
---

# ppkg-where

## SYNOPSIS
Gets the full path of an installed binary.

## SYNTAX

```
ppkg-where [-shim] <String[]> [<CommonParameters>]
```

## DESCRIPTION
The `ppkg-where` cmdlet gets the full path to an installed binary.

## EXAMPLES

### Example 1: Get the path of an installed binary
```powershell
PS> ppkg-where ripgrep
```

## PARAMETERS

### -shim
The name of a shim

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String[]

## OUTPUTS

### System.String

## NOTES

## RELATED LINKS
