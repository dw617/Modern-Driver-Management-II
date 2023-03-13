#date = MMDDYY

$DriverPackageFiles = Get-ChildItem -Path "\\corp\sites\SCCMSOURCE\DSK\OSD\Drivers\DEV" -Recurse | where { ! $_.PSIsContainer }


$MFGregex = "Dell"
$modelregex = "\b\d{4}\b"
$makeregex = "Precision|Latitude|OptiPlex"
$driverregex = "[A][0-9]{2}"
$uniquemakematchregex = "2-IN-1|2in1|Detachable"



foreach ($DriverPackageFile in $DriverPackageFiles ) {
$driverPackageName = $DriverPackageFile.Name
$driverPackageNameFull = $DriverPackageFile.FullName
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

write-host "-----------------------------"
write-host "Filename: " $driverPackageNameFull`n
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
    if($MatchedModel -match "[30]{2}") {
        $MatchedMake = "OptiPlex"
        }
    if($MatchedModel -match "[50]{2}") {
        $MatchedMake = "OptiPlex"
        }
    if($MatchedModel -match "[54]{2}") {
        $MatchedMake = "Latitude"
        }
    if($MatchedModel -match "[72|73|74]{2}") {
        $MatchedMake = "Latitude"
        }
    if($MatchedModel -match "[75|76]{2}") {
        $MatchedMake = "Precision"
        }
        if($MatchedModel -match "[73|93]{2}") {
        $MatchedMake = "XPS"
        }
     }

#Unique Model Name Logic
if ($UniqueMake) {
    if($MatchedModel -eq "7390") {
        $MatchedModel = "7390 2in1"
        }
    if($MatchedModel -eq "7320") {
        $MatchedModel = "7320 Detachable"
        }
    if($MatchedModel -eq "7400") {
        $MatchedModel = "7400 2-in-1"
        }
    if($MatchedModel -eq "9310") {
        $MatchedModel = "13 2in1 9310"
        }
    if($MatchedModel -eq "5820") {
        $MatchedModel = "5820 Tower"
        }
    }



write-host "Variables"`n`n"Mfgr:"$MatchedMFG`n"Make:"$MatchedMake`n"Model:"$MatchedModel`n"Driver Ver:"$MatchedDriverVer`n"Date:"$date`n"Extension"($driverPackageExt.Trim("."))`n

#validation 

if ($MatchedMFG -and $MatchedMake -and $MatchedModel -and $MatchedDriverVer) { write-host "All filename variables validated" -ForegroundColor Green}
 
    else {write-host "Check logic" -ForegroundColor red}
    }
    
  