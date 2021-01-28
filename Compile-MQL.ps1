#gets the File To Compile as an external parameter... Defaults to a Test file...
Param( $FileToCompile = "${workspaceFolder}/Experts/DG/DG_DaveLandry.mq5")
Param( $Mt5Editor = "D:/Programs/MT5/Demo04/metaeditor64.exe")
Param( $Mt5Terminal = "D:/Programs/MT5/Demo04/terminal64.exe")

#cleans the terminal screen and sets the log file name...
Clear-Host

New-Item -ErrorAction SilentlyContinue -ItemType Directory -Path "Build" | Out-Null
$LogFile = "Build/" + [System.IO.Path]::GetFileNameWithoutExtension($FileToCompile) + ".log"

#before continue check if the Compile File has any spaces in it...
if ($FileToCompile.Contains(" ")) {
    "";"";
    Write-Host "ERROR!  Impossible to Compile! Your Filename or Path contains SPACES!" -ForegroundColor Red;
    "";
    Write-Host $FileToCompile -ForegroundColor Red;
    "";"";
    return;
}

#first of all, kill MT Terminal (if running)... otherwise it will not see the new compiled version of the code...
Get-Process -Name terminal64 -ErrorAction SilentlyContinue | Where-Object {$_.Id -gt 0} | Stop-Process

#fires up the Metaeditor compiler...
& "$Mt5Editor" /compile:"$FileToCompile" /log:"$LogFile" /inc:"${workspaceFolder}" | Out-Null

#get some clean real state and tells the user what is being compiled (just the file name, no path)...
"";"";"";"";""
$JustTheFileName = Split-Path $FileToCompile -Leaf
Write-Host "Compiling........: $JustTheFileName"
""

#reads the log file. Eliminates the blank lines. Skip the first line because it is useless.
$Log = Get-Content -Path $LogFile | Where-Object {$_ -ne ""} | Select-Object -Skip 1

#Green color for successful Compilation. Otherwise (error/warning), Red!
$WhichColor = "Red"
$Log | ForEach-Object { if ($_.Contains("0 errors")) { $WhichColor="Green" } }

#runs through all the log lines...
$Log | ForEach-Object {
     #ignores the ": information: error generating code" line when ME was successful
     if (-Not $_.Contains("information:")) 
     {
           #common log line... just print it...
           Write-Host $_ -ForegroundColor $WhichColor
     }
}

#get the MT Terminal back if all went well...
if ( $WhichColor -eq "Green") { & "$Mt5Terminal" }

