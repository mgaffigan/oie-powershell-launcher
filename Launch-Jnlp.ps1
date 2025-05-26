param (
    [Parameter(Mandatory = $true)]
    [string]$Url
)

# Base directory is based on the URL
$hashString = Get-FileHash -InputStream ([System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($Url))) -Algorithm SHA1 | Select-Object -ExpandProperty Hash
$basePath = "$env:TEMP\$hashString"
Write-Host "Downloading to $basePath" -ForegroundColor Green;
New-Item -ItemType Directory -Path $basePath -Force | Out-Null;

# Download the JNLP file
$jnlpFilePath = "$basePath\launch.jnlp"
Invoke-WebRequest -Uri $Url -OutFile $jnlpFilePath
$jnlpXml = ([xml](Get-Content -Path $jnlpFilePath)).jnlp;
$baseUrl = [Uri]$Url;
if ($jnlpXml.codebase) {
    $baseUrl = [Uri]$jnlpXml.codebase;
}

# Download JAR's
$jarList = @();
function DownloadJars($xml, $codebase) {
    foreach ($jar in $xml.resources.jar) {
        $jarUrl = [Uri]::new($codebase, [Uri]$jar.href);
        $filename = $jarUrl.Segments[-1];
        $jarPath = Join-Path $basePath $filename;
        Write-Output $filename;

        # $jar.sha256 is the base64 encoded SHA256 hash of the JAR file
        # we want the upper-case hexadecimal representation
        $sha256 = [Convert]::ToHexString([Convert]::FromBase64String($jar.sha256));
        if ((Test-Path $jarPath) -and ($sha256 -eq (Get-FileHash -Path $jarPath -Algorithm SHA256).Hash)) {
            continue;
        }

        Write-Host "Downloading $filename" -ForegroundColor Cyan;
        Invoke-WebRequest -Uri $jarUrl -OutFile $jarPath;
    }
}
$jarList += DownloadJars $jnlpXml $baseUrl;
foreach ($ext in $jnlpXml.resources.extension) {
    $extUrl = [Uri]::new($baseUrl, [Uri]$ext.href);
    $extPath = Join-Path $basePath $extUrl.Segments[-1];
    Invoke-WebRequest -Uri $extUrl -OutFile $extPath;
    $extXml = ([xml](Get-Content -Path $extPath)).jnlp;
    $jarList += DownloadJars $extXml $extUrl;
}

# Get the class name and arguments
$mainClass = $jnlpXml.'application-desc'.'main-class';
$arguments = @('-Xmx512m', '-cp', ($jarList -join ';'), $mainClass);
foreach ($arg in $jnlpXml.'application-desc'.argument) {
    $arguments += $arg;
}

# Create the Java command
$javaExe = 'java.exe';
if ($env:JAVA_HOME) {
    $javaExe = Join-Path $env:JAVA_HOME 'bin\java.exe';
}
Write-Host "Starting Java application with the following command:" + `
    "`njava.exe $($arguments -join ' ')`n";
Start-Process $javaExe -ArgumentList $arguments -NoNewWindow -WorkingDirectory $basePath;
