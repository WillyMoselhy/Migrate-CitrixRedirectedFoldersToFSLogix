@{
	# Script module or binary module file associated with this manifest
	RootModule = 'MigrateCitrixUPMtoFSLogix.psm1'

	# Version number of this module.
	ModuleVersion = '1.0.0'

	# ID used to uniquely identify this module
	GUID = '8b3fdf29-a609-4dbe-82f6-72a91a0a42ee'

	# Author of this module
	Author = 'wmoselhy'

	# Company or vendor of this module
	CompanyName = 'MyCompany'

	# Copyright statement for this module
	Copyright = 'Copyright (c) 2021 wmoselhy'

	# Description of the functionality provided by this module
	Description = 'A module to migrate from Citrix UPM and Redirected Folders to FSLogix by precreating VHDs'

	# Minimum version of the Windows PowerShell engine required by this module
	PowerShellVersion = '5.1'

	# Modules that must be imported into the global environment prior to importing
	# this module
	RequiredModules = @(
		@{ ModuleName='PSFramework'; ModuleVersion='1.6.201' }
	)

	# Assemblies that must be loaded prior to importing this module
	# RequiredAssemblies = @('bin\MigrateCitrixUPMtoFSLogix.dll')

	# Type files (.ps1xml) to be loaded when importing this module
	# TypesToProcess = @('xml\MigrateCitrixUPMtoFSLogix.Types.ps1xml')

	# Format files (.ps1xml) to be loaded when importing this module
	# FormatsToProcess = @('xml\MigrateCitrixUPMtoFSLogix.Format.ps1xml')

	# Functions to export from this module
	FunctionsToExport = @('Convert-CFXUser')

	# Cmdlets to export from this module
	CmdletsToExport = ''

	# Variables to export from this module
	VariablesToExport = ''

	# Aliases to export from this module
	AliasesToExport = ''

	# List of all modules packaged with this module
	ModuleList = @()

	# List of all files packaged with this module
	FileList = @()

	# Private data to pass to the module specified in ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
	PrivateData = @{

		#Support for PowerShellGet galleries.
		PSData = @{

			# Tags applied to this module. These help with module discovery in online galleries.
			# Tags = @()

			# A URL to the license for this module.
			# LicenseUri = ''

			# A URL to the main website for this project.
			# ProjectUri = ''

			# A URL to an icon representing this module.
			# IconUri = ''

			# ReleaseNotes of this module
			# ReleaseNotes = ''

		} # End of PSData hashtable

	} # End of PrivateData hashtable
}