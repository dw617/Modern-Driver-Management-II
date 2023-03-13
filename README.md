# Modern-Driver-Management-II
My take on SCCM OSD Modern Driver Management

I created this process to help manage OSD Driver packs in a Dell environment. Use at your own risk!

High level on how this works
* In our CM fileshare - DEV and PROD folders, each have subfolders that align to the WMIC Model of the endpoint (ex : Latitude 5430).
* Enterprise driver pack from Dell gets placed in each folder and a package is created.
* In the TS, I align the packageID to Make/Model query.
* Powershell script does the rest: > 
    * Downloads content 
    * Reads the filename, pulls out Make, Model, Driver Version, OS version, etc - captures these as variables. Dell doesn't have consistent filenames for driver packs,        so there's a bunch of regex matching to help with this.
    * Extracts exe or cab file, then runs dism with a recurse to install the drivers.
    * Various reporting bits to our OSD dashboard, local registry and a log file is written in the ccm logs area.In our CM fileshare - DEV and PROD folders, each have          subfolders that align to the WMIC Model of the endpoint (ex : Latitude 5430).
