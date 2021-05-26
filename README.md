# Description

This is PowerShell module to aid the migration from Citrix UPM and Redirected folders into FSLogix.
The modules utilizes FSLogix's FRX.exe to create VHD files from existing UPM profiles, then add files in redirected folders into the disk.
It then copies the VHD into FSLogix providers (SMB File shares), and optionally add the user to an AD Group.

Output includes success or failure and information on copied files.

# Installation
Get the latest version by running `Import-Module -Name $MigrateCitrixUPMtoFSLogix` or by building the module from source code on GitHub.

# Prerequisites
The PowerShell module will install PSFramework, it also require Active Directory module to get the SIDs and add to AD Group if used.

# Usage
Review the example runner script 'MigrationScript.ps1'. It logs results into file as well as show it on screen.
