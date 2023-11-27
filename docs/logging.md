# Logging
PPKG creates logging events you can subscribe to and run arbitrary code on.

The event source identifier for all logging events is `PPKG.Log`.

By leveraging Powershell events you can, for example, send logs to a log aggregator, write logs to a file, or anything you can think of.

## Subscribing To Logging Events
All you need to do is register an event handler:
```powershell
Register-EngineEvent -SourceIdentifier PPKG.Log -Action {
	# $event is a powershell automatic variable
	$log = $event.messageData
	#logLevel = $log.level # one of "error", "warning", "info", "trace"
	$logMessage = $log.message
	# Do things with these values
}
```

## Example: Write all logs to a file
```powershell
Register-EngineEvent -SourceIdentifier PPKG.Log -Action {
	$date = get-date -uformat "%Y-%m-%d %T"
	$level = $event.messageData.level
	$message = $event.messageData.message
	"[$date] [$level] $message" | out-file -append "$home\ppkg.log"
}
```
