# RouterOS Scripts

Create, update, deliver scripts to Mikrotik from git repository.

## Installation

```

:foreach Script in={ "global-functions" } do={ /system/script/add name=$Script owner=$Script source=([ /tool/fetch ("https://raw.githubusercontent.com/alikhil/routeros-scripts/main/" . $Script . ".rsc") output=user as-value]->"data"); };


/system/script { run global-functions; };
/system/scheduler/add name="global-scripts" start-time=startup on-event="/system/script { run global-functions; }";
```

## Update

```
$updateFunctions
```
