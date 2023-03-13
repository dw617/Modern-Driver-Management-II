<#
    Script name: StageDrivers.ps1
    Version: 2.1
    Author: DW617
    Date: 2021-04-23
    Note: Concept, use at own risk
	v 0.2 = Removing need for self extracting password. (This script was developed by the old OSD Admin)
    v2.0 = Removing DriverPackage.exe and moving back to .cab or .exe files. Added Get-FileNameAttribs and other smarter logic.
    v2.1 = Cleaned up code.

    Functions
    * WriteLog - responsible for writing the log file
    * Start-Proc - Start-Process. This is now native to Powershell but was here in the original 0.2version. Could probably remove.
    * Set-RunFromDP - Sets/toggles the _SMSTSRunFromDP variable
    * Get-FileNameAttribs - Parses through the Dell (or other OEM) driverfile name and pulls out / aligns information, outputs that information as an array via $DriverInfoArray
	
#>

function WriteLog {
    param(
    [Parameter(Mandatory)]
    [string]$LogText,
    [Parameter(Mandatory=$true)]
    $Component,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('Info','Warning','Error','Verbose')]
    [string]$Type,
    [Parameter(Mandatory)]
    [string]$LogFileName,
    [Parameter(Mandatory)]
    [string]$FileName
    )

    switch ($Type)
    {
        "Info"      { $typeint = 1 }
        "Warning"   { $typeint = 2 }
        "Error"     { $typeint = 3 }
        "Verbose"   { $typeint = 4 }
    }

    $time = Get-Date -f "HH:mm:ss.ffffff"
    $date = Get-Date -f "MM-dd-yyyy"
    $ParsedLog = "<![LOG[$($LogText)]LOG]!><time=`"$($time)`" date=`"$($date)`" component=`"$($Component)`" context=`"`" type=`"$($typeint)`" thread=`"$($pid)`" file=`"$($FileName)`">"
    $ParsedLog | Out-File -FilePath "$LogFileName" -Append -Encoding utf8
}

function Start-Proc {
    param([string]$Exe = $(Throw "An executable must be specified"),
          [string]$Arguments,
          [string]$WorkDir = $null,
          [switch]$Hidden,
          [switch]$WaitForExit)

    $startinfo = New-Object System.Diagnostics.ProcessStartInfo
    $startinfo.FileName = $Exe
    $startinfo.Arguments = $Arguments
    $startinfo.WorkingDirectory = "$($WorkDir)"
    if ($Hidden) {
        $startinfo.WindowStyle = 'Hidden'
        $startinfo.CreateNoWindow = $True
    }
    $process = [System.Diagnostics.Process]::Start($startinfo)
    if ($WaitForExit) { $process.WaitForExit() }
    return $process.ExitCode
}

function Set-RunFromDP {
    param([string]$Value)

    $Arch = "x86"

    if($env:PROCESSOR_ARCHITECTURE.Equals("AMD64")) {
        $Arch = "x64"
    }
    
    $Arg = "set _SMSTSRunFromDP $($Value)"

    $result = Start-Proc -Exe "TSVars.exe" -Arguments $Arg -WorkDir "$($PSScriptRoot)\$($Arch)" -Hidden -WaitForExit
}

Function Get-FileNameAttribs($DriverFileLocation) {

WriteLog -LogFileName "$LogFile" -Component "RunPowerShellScript" -FileName "$Self" -LogText "Starting Function" -Type Info


$DriverPackageFiles = Get-ChildItem -Path $DriverFileLocation
#Path is going to be path of package - DriverContentPath01

WriteLog -LogFileName "$LogFile" -Component "RunPowerShellScript" -FileName "$Self" -LogText "DriverPackageFile = $DriverPackageFiles" -Type Info

#write-host "Driver files " $DriverPackageFiles

$MFGregex = "Dell"
$modelregex = "\b\d{4}\b"
$makeregex = "Precision|Latitude|OptiPlex"
$driverregex = "[A][0-9]{2}"
$uniquemakematchregex = "2-IN-1|2in1|Detachable"

WriteLog -LogFileName "$LogFile" -Component "RunPowerShellScript" -FileName "$Self" -LogText "DriverPackageFilesCount = $($DriverPackageFiles.count)" -Type Info

#Check if there are more than 1 files and return an error if so.
#There should only be one driver package per directory
if($DriverPackageFiles.count -eq 1) {

$DriverPackageFile = $DriverPackageFiles

#$count = $FileNameArray.count

$driverPackageName = $DriverPackageFile.Name
$driverPackageExt = $DriverPackageFile.Extension

$day = $DriverPackageFile.LastwriteTime.Date.ToString("dd")
$month = $DriverPackageFile.LastwriteTime.Date.ToString("MM")
$year = $DriverPackageFile.LastwriteTime.Date.ToString("yy")
$date =  $day + $month + $year

$MatchedMFG = $null
$MatchedDriverVer = $null
$MatchedMake = $null


$FileNameArray = $driverPackageName.split("-_. ")
$count = $FileNameArray.count

WriteLog -LogFileName "$LogFile" -Component "RunPowerShellScript" -FileName "$Self" -LogText "FileNameArrayCount  = $count" -Type Info
WriteLog -LogFileName "$LogFile" -Component "RunPowerShellScript" -FileName "$Self" -LogText "FileNameArray = $FileNameArray" -Type Info


#write-host "-----------------------------"
#write-host "Filename: " $driverPackageName`n
$i = 0
do {
#write-host $FileNameArray[$i]
if ($FileNameArray[$i] -match $MFGregex) {
    #write-host "MFG: " $matches[0]
    $MatchedMFG  = $matches[0]
    } 

if ($FileNameArray[$i] -match $driverregex) {
    #write-host "DriverVer: " $matches[0]
    $MatchedDriverVer  = $matches[0]
    } 

if ($FileNameArray[$i] -match $makeregex) {
    #write-host "Make: " $matches[0]
    $MatchedMake = $matches[0]
    
    }
  
if ($FileNameArray[$i] -match $modelregex) {
    #write-host "Model: " $matches[0]
    $MatchedModel = $matches[0]} 

if ($FileNameArray[$i] -match $uniquemakematchregex) {
    #write-host "Model: " $matches[0]
    $UniqueMake = $matches[0]} 

$i++

} until ($i -eq $count)

#Manfaucturer Logic
if (!$MatchedMFG) {$MatchedMFG =  "Dell"}
#Write-host "MFG:" $MatchedMFG

#Model Logic
if (!$MatchedMake) {
    if($MatchedModel -match "[3]{1}") {
        $MatchedMake = "OptiPlex"
        }
    if($MatchedModel -match "[5]{1}") {
        $MatchedMake = "Latitude"
        }
    if($MatchedModel -match "[72|73|74]{2}") {
        $MatchedMake = "Latitude"
        }
    if($MatchedModel -match "[75]{2}") {
        $MatchedMake = "Precision"
        }
     }

#Unique Model Name Logic
if ($UniqueMake) {
    if($MatchedModel -eq "7390") {
        $MatchedModel = "XPS 13 7390 2-in-1"
        }
    if($MatchedModel -eq "7320") {
        $MatchedModel = "7320 Detachable"
        }
    if($MatchedModel -eq "7400") {
        $MatchedModel = "7400 2-in-1"
        }
    if($MatchedModel -eq "9310") {
        $MatchedModel = "XPS 13 9310 2-in-1"
        }
    }


#set additional variables to return
$CFGWMICModel = (Get-WmiObject -Class:Win32_ComputerSystem).model
$DriverExt = $driverPackageExt.Trim(".")
$DriverPackageFileName = $DriverPackageFile.name
$DriverPackageFileNameFull = $DriverPackageFile.FullName

#WriteLog -LogFileName "$LogFile" -Component "RunPowerShellScript" -FileName "$Self" -LogText ""Variables"`n`n"Mfgr:"$MatchedMFG`n"Make:"$MatchedMake`n"Model:"$MatchedModel`n"WMICModel:"$CFGWMICModel`n"Driver Ver:"$MatchedDriverVer`n"Date:"$date`n"Extension:"$DriverExt`n" -Type Info

write-host "Variables"`n`n"Mfgr:"$MatchedMFG`n"Make:"$MatchedMake`n"Model:"$MatchedModel`n"WMICModel:"$CFGWMICModel`n"Driver Ver:"$MatchedDriverVer`n"Date:"$date`n"Extension:"$DriverExt`n

$DriverFileInfo= @($DriverPackageFileName, $MatchedMFG, $MatchedMake, $MatchedModel, $CFGWMICModel, $MatchedDriverVer, $date, $DriverExt,$DriverPackageFileNameFull )

Return $DriverFileInfo

#if ($MatchedMFG -and $MatchedMake -and $MatchedModel -and $MatchedDriverVer) { write-host "All filename variables validated" -ForegroundColor Green}

  #  } else {write-host "Missing Variables, please check filename and logic"}

    
  } else {
    #write-host "Too many driver files 
    $DriverFileInfo = "false"
    Return $DriverFileInfo
    }

  } 

#some top level variables
#OSDDriverPackageID is set in the Task Sequence for each model

$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment

[string]$OSDDriverPackageID = $tsenv.Value("OSDDriverPackageID")
[string]$TargetDisk = $tsenv.Value("OSDTargetSystemDrive")
[string]$ContentPathOnDisk = "$($TargetDisk)\Drivers"
[bool]$SMSTSRunFromDP = $tsenv.Value("_SMSTSRunFromDP").ToLower().Equals("true")
[bool]$SMSTSInWinPE = $tsenv.Value("_SMSTSInWinPE").ToLower().Equals("true")
[string]$LogPath = $tsenv.Value("_SMSTSLogPath")


$self = "CFG-DriverInstall"
$LogFile = "$LogPath\CFG-DriverInstall.Log"
#$OSDisk = $LogFile.SubString(0, 2)

WriteLog -LogFileName "$LogFile" -Component "RunPowerShellScript" -FileName "$Self" -LogText "Script started" -Type Info

#checks arch and assigns the correct OSDDownloadContent exe. These days everything is x64 though.
if ($env:PROCESSOR_ARCHITECTURE.Equals("AMD64")) {
    WriteLog -LogFileName "$LogFile" -Component "RunPowerShellScript" -FileName "$Self" -LogText "Detected 64-bit environment" -Type Info
    $DownLoadExe = "X:\sms\bin\x64\OSDDownloadContent.exe"
}
else {
    WriteLog -LogFileName "$LogFile" -Component "RunPowerShellScript" -FileName "$Self" -LogText "Detected 32-bit environment" -Type Info
    $DownLoadExe = "X:\sms\bin\i386\OSDDownloadContent.exe"
}

WriteLog -LogFileName "$LogFile" -Component "RunPowerShellScript" -FileName "$Self" -LogText "Setting TS variables for dynamic download" -Type Info

#set variables for the package download via OSDDownloadContent
$tsenv.Value("OSDDownLoadDownloadPackages") = "$OSDDriverPackageID"
$tsenv.Value("OSDDownloadDestinationLocationType") = "Custom"
$tsenv.Value("OSDDownloadDestinationPath") = "$ContentPathOnDisk"
$tsenv.Value("OSDDownloadDestinationVariable") = "DriverContentPath"
$tsenv.Value("OSDDownloadContinueDownloadOnError") = "True"

#checks _SMSTSRunFromDP and starts the download. This section was written/carried over from the original script.
try {

    if ($SMSTSRunFromDP) {
        WriteLog -LogFileName "$LogFile" -Component "RunPowerShellScript" -FileName "$Self" -LogText "Flipping '_SMSTSRunFromDP' to enable download" -Type Info
        Set-RunFromDP -Value "false"
    }

    WriteLog -LogFileName "$LogFile" -Component "RunPowerShellScript" -FileName "$Self" -LogText "Starting download of Package $($OSDDriverPackageID)" -Type Info
    $result = Start-Proc -Exe "$DownLoadExe" -Hidden -WaitForExit

    if ($SMSTSRunFromDP) {
        WriteLog -LogFileName "$LogFile" -Component "RunPowerShellScript" -FileName "$Self" -LogText "Restoring '_SMSTSRunFromDP' after download" -Type Info
        Set-RunFromDP -Value "false"
    }
}
catch {
    WriteLog -LogFileName "$LogFile" -Component "RunPowerShellScript" -FileName "$Self" -LogText "Failed to download, Exception: $($_.Exception.Message)" -Type Error
}

WriteLog -LogFileName "$LogFile" -Component "RunPowerShellScript" -FileName "$Self" -LogText "Resetting variables" -Type Info

#resets variables, carried over from original script
$tsenv.Value("OSDDownLoadDownloadPackages") = ""
$tsenv.Value("OSDDownloadDestinationLocationType") = ""
$tsenv.Value("OSDDownloadDestinationPath") = ""
$tsenv.Value("OSDDownloadDestinationVariable") = ""
$tsenv.Value("OSDDownloadContinueDownloadOnError") = ""

#driver cab/exe content location below
$ContentLocation = $tsenv.Value("DriverContentPath01")


#makes sure content was downloaded
if (!$ContentLocation) {
    WriteLog -LogFileName "$LogFile" -Component "RunPowerShellScript" -FileName "$Self" -LogText "$($ContentLocation) doesn't exist, exiting" -Type Info
    exit 1
}



WriteLog -LogFileName "$LogFile" -Component "RunPowerShellScript" -FileName "$Self" -LogText "ContentLocation = $($ContentLocation)" -Type Info

WriteLog -LogFileName "$LogFile" -Component "RunPowerShellScript" -FileName "$Self" -LogText "Running GetFileNameAttribs Function" -Type Info

#gather info from Get-FileNameAttribs

$DriverInfoArray = Get-FileNameAttribs($ContentLocation) 

#------------------------------

#grab OSD Variables from function

$tsenv.Value("CFGDriverFileName") = $($DriverInfoArray[0])
$tsenv.Value("CFGDriverMFG") = $($DriverInfoArray[1])
$tsenv.Value("CFGDriverMake") = $($DriverInfoArray[2])
$tsenv.Value("CFGDriverModel") = $($DriverInfoArray[3])
$tsenv.Value("CFGDriverWMICModel") = $($DriverInfoArray[4])
$tsenv.Value("CFGDriverVersion") = $($DriverInfoArray[5])
$tsenv.Value("CFGDriverDate") = $($DriverInfoArray[6])
$tsenv.Value("CFGDriverExtension") = $($DriverInfoArray[7])
$tsenv.Value("CFGDriverFileNameFull") = $($DriverInfoArray[8])
#$tsenv.Value("CFGDriverVarTest") = "Test Var"


$DriverFile = $CFGDriverFileNameFull

#$DriverExtractedContent = Join-Path -Path $ContentPathOnDisk -ChildPath $DriverInfoArray[4]
#new-item -Path $DriverExtractedContent -type Directory -force | out-null
$DriverExtractedContent = "c:\drivers"


if (!(Test-Path -Path "$($DriverInfoArray[8])")) {
    WriteLog -LogFileName "$LogFile" -Component "RunPowerShellScript" -FileName "$Self" -LogText "Driver Filedoes not exist, exiting" -Type Info
    exit 1
}

#WriteLog -LogFileName "$LogFile" -Component "RunPowerShellScript" -FileName "$Self" -LogText "Driver File = $($DriverFile)" -Type Info
WriteLog -LogFileName "$LogFile" -Component "RunPowerShellScript" -FileName "$Self" -LogText "Driver Full = $($DriverInfoArray[8])" -Type Info


#extract CAB - different logic for CAB vs EXE packages.
#cmd.exe /c "C:\Windows\System32\expand.exe -F: <filename.cab> <full folder location>

if($DriverInfoArray[7] -eq "CAB") {

try {

    $result = Start-Proc expand.exe -Arguments "-F:* $($DriverInfoArray[8]) $($DriverExtractedContent)"
    WriteLog -LogFileName "$LogFile" -Component "RunPowerShellScript" -FileName "$Self" -LogText "Expanded $($DriverInfoArray[8]) to '$($DriverExtractedContent)'" -Type Info
}
catch {
    WriteLog -LogFileName "$LogFile" -Component "RunPowerShellScript" -FileName "$Self" -LogText "Failed to expand $($DriverInfoArray[8]), Exception: $($_.Exception.Message)" -Type Error
    exit 1
}


#sleep to allow file extraction before DISM
WriteLog -LogFileName "$LogFile" -Component "RunPowerShellScript" -FileName "$Self" -LogText "Sleeping for 150 seconds to allow for cab/exe extraction" -Type Info
start-sleep -Seconds 150

try {
    WriteLog -LogFileName "$LogFile" -Component "RunPowerShellScript" -FileName "$Self" -LogText "Running Dism.exe /Image:$($TargetDisk)\ /Add-Driver /Driver:$($DriverExtractedContent) /Recurse" -Type Info
    $result = Start-Proc -Exe "Dism.exe" -Arguments "/Image:$($TargetDisk)\ /Add-Driver /Driver:$($DriverExtractedContent) /Recurse" -Hidden -WaitForExit
}
catch {
    WriteLog -LogFileName "$LogFile" -Component "RunPowerShellScript" -FileName "$Self" -LogText "Failed to run dism /recurse, Exception: $($_.Exception.Message)" -Type Error
    exit 1
}
}

#extract EXE - different logic for CAB vs EXE packages.
if($DriverInfoArray[7] -eq "exe") {
    try {

    $result = Start-Proc $($DriverInfoArray[8]) -Arguments "/s /e=$($DriverExtractedContent)"
    #Remove-Item -Path "$($ContentLocation)" -Recurse -Force -EA SilentlyContinue
    WriteLog -LogFileName "$LogFile" -Component "RunPowerShellScript" -FileName "$Self" -LogText "Extracted $($DriverInfoArray[8]) to $($DriverExtractedContent)" -Type Info
}
catch {
    WriteLog -LogFileName "$LogFile" -Component "RunPowerShellScript" -FileName "$Self" -LogText "Failed to run and install $($DriverInfoArray[8]), Exception: $($_.Exception.Message)" -Type Error
    exit 1
}


#sleep to allow file extraction before DISM
#This area could be improved as the same DISM commands are written twice (cab/exe)
WriteLog -LogFileName "$LogFile" -Component "RunPowerShellScript" -FileName "$Self" -LogText "Sleeping for 150 seconds to allow for cab/exe extraction" -Type Info
start-sleep -Seconds 150

try {
    WriteLog -LogFileName "$LogFile" -Component "RunPowerShellScript" -FileName "$Self" -LogText "Running Dism.exe /Image:$($TargetDisk)\ /Add-Driver /Driver:$($DriverExtractedContent) /Recurse" -Type Info
    $result = Start-Proc -Exe "Dism.exe" -Arguments "/Image:$($TargetDisk)\ /Add-Driver /Driver:$($DriverExtractedContent) /Recurse" -Hidden -WaitForExit
}
catch {
    WriteLog -LogFileName "$LogFile" -Component "RunPowerShellScript" -FileName "$Self" -LogText "Failed to run dism /recurse, Exception: $($_.Exception.Message)" -Type Error
    exit 1



}
}

Start-Sleep -Milliseconds 2000
WriteLog -LogFileName "$LogFile" -Component "RunPowerShellScript" -FileName "$Self" -LogText "Script finished successfully" -Type Info
