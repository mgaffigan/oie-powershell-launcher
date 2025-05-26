# oie-powershell-launcher
Minimal powershell jnlp launcher. 

## Usage

```powershell
& .\Launch-Jnlp -Url 'http://localhost:8080/webstart.jnlp'
```

Jars will be downloaded to `%TEMP%` based on url and used if hash matches.
`$env:JAVA_HOME` will be used.