# EDIT HERE

$Users = Import-CSV -Path C:\FSLogixMigration\UsersToMigrate.txt
$LogFolder = 'C:\FSLogixMigration\Logs'
$DomainController = 'DC01' # Domain controller in the same site as VDI servers

$CitrixUPMProfilePath  = '\\FileServer\CitrixUPM\%username%\Win2016\UPM_Profile'
$RedirectedFoldersPath = '\\FileServer\RedirectedFolders\%username%'
$FSLogixProviderPath   = @('\\FileServer1\FSLogixProfiles','\\FileServer2\FSLogixProfiles')


# DO NOT EDIT HERE

#Requires -RunAsAdministrator

Import-Module MigrateCitrixUPMtoFSLogix -Force

$PSDefaultParameterValues = @{
    '*-AD*:Server' = $DomainController
}

$Migration = Convert-CFXUser -Username $users.username `
    -CitrixUPMProfilePath $CitrixUPMProfilePath `
    -RedirectedFoldersPath $RedirectedFoldersPath `
    -FSLogixProviderPath $FSLogixProviderPath  `
    -SetFSLogixOwner  `
    -ADGroupName 'FSLogix Users'

$datetime = Get-Date -f yyyyMMdd-HHmmss
$ResultsPath = Join-Path $LogFolder "Migration-$datetime.csv"
$CopyResultsPAth = Join-Path $LogFolder "Migration-$datetime-CopyResults.csv"

$Migration | Select-Object -Property * -ExcludeProperty CopyResults | Export-Csv -Path $ResultsPath -NoTypeInformation
$Migration |where CopyResults -ne $null |foreach-Object {
    $username = $_.username
    $_.CopyResults | Select-Object @{l='Username';e={$username}},ProviderPath,CopyDuration,CopySpeedMBps | Export-Csv -Path $CopyResultsPAth -NoTypeInformation -Append
}

$Migration | select -Property username,success,ErrorMessage | ft -AutoSize
write-host "For more details please review logs dated: $datetime" -ForegroundColor Cyan
