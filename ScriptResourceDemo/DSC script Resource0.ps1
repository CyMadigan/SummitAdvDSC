﻿$ConfigData = @{
    AllNodes = @(
        @{
            NodeName = '*'
           }
      
     @{
            NodeName = 'DC1'
        }
    )
}
   

configuration Backup {
   
        
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node DC1 {
        
        WindowsFeature Windows-Server-Backup {
            Name = 'Windows-Server-Backup'
            Ensure = 'Present'
            }

        #Windows-Server-Backup is needed for cmdlets to be available - need DependsOn
        Script NewSSBUPolicy {
            TestScript = {
                $policy = get-wbPolicy
                if (($Policy -ne $Null) -and ($Policy.SystemState -eq $True) -and ($Policy.schedule -eq ([datetime]::today.AddHours(21)))) {return $True}
                else {return $False}
                }
            SetScript = {
                $BackupTime = [datetime]::today.AddHours(21)
                $Policy = New-WBPolicy
                Set-WBSchedule -Policy $Policy -Schedule $BackupTime
                $Target = New-WBBackupTarget -Disk (get-wbdisk | Where-Object {$_.DiskNumber -eq 1})
                Add-WBBackupTarget -Policy $Policy -Target $Target -force
                Add-WBSystemState -Policy $Policy
                Set-WBPolicy -AllowDeleteOldBackups -Policy $Policy -force
                }
            GetScript = {
                $Policy = get-wbPolicy
                return @{Result = $policy.Schedule}
                }
            DependsOn = '[WindowsFeature]Windows-Server-Backup'
        }
    }             
}
Backup -ConfigurationData $ConfigData -OutputPath C:\DSC\Configs