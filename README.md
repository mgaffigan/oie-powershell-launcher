# oie-powershell-launcher
Minimal powershell jnlp launcher. 

## Usage

```powershell
& .\Launch-Jnlp -Url 'http://localhost:8080/webstart.jnlp'
```

Jars will be downloaded to the platform temp directory based on URL and reused if the hash matches.
`$env:JAVA_HOME` will be used when set.