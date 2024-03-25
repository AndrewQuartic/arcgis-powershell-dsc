Configuration DiskConfiguration
{   	
    Import-DscResource -ModuleName PSDesiredStateConfiguration 
    Import-DSCResource -ModuleName ArcGIS
    Import-DscResource -Name ArcGIS_xDisk     
    Import-DscResource -Name ArcGIS_Disk
    
    Node localhost
    {   
		LocalConfigurationManager
        {
			ActionAfterReboot = 'ContinueConfiguration'            
            ConfigurationMode = 'ApplyOnly'    
            RebootNodeIfNeeded = $true
        }

		ArcGIS_Disk OSDiskSize
        {
            DriveLetter = 'C'
            SizeInGB    = 4096
        }

        $Depends = @()
        $UnallocatedDataDisks = Get-Disk | Where-Object partitionstyle -eq 'raw' | Sort-Object number

        # Initialize an array of disks starting with F
        $Letters = 70..89 | ForEach-Object { [char]$_ }
        $Count = 0

        # iterate though unallocated disks and partition each in sequence ordered by disk number
        foreach ($Disk in $UnallocatedDataDisks) {
            $DataDiskDriveLetter = $Letters[$Count].ToString()
            ArcGIS_xDisk DataDisk${DataDiskDriveLetter}
			{
				DiskNumber = $Disk.number
				DriveLetter = $DataDiskDriveLetter
			}   
            if(Get-Partition -DriveLetter $DataDiskDriveLetter -ErrorAction Ignore) 
            {
                ArcGIS_Disk DataDiskSize
                {
                    DriveLetter = $DataDiskDriveLetter
                    SizeInGB    = 4095
                    DependsOn   = $Depends			
                }	
            }
            $Depends += "[ArcGIS_xDisk]DataDisk${DataDiskDriveLetter}"
            $Count++
        }
    }
}
