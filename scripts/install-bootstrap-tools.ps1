Function Set-Registry-Values {
  New-Item -Path "HKLM:\System\CurrentControlSet\Control\Network\NewNetworkWindowOff"
  # File browser config
  New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\" -Name "HideFileExt" -PropertyType "DWORD" -Value "0" -Force
  New-ItemProperty -Path "HKCU:\Console" -Name "QuickEdit" -PropertyType "DWORD" -Value "1" -Force
  New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\" -Name "Start_ShowRun" -PropertyType "DWORD" -Value "1" -Force
  New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\" -Name "StartMenuAdminTools" -PropertyType "DWORD" -Value "1" -Force
  # Disable Hibernation
  New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\" -Name "HibernateFileSizePercent" -PropertyType "DWORD" -Value "0" -Force
  New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\" -Name "HibernateEnabled" -PropertyType "DWORD" -Value "0" -Force
  # Disable Windows Defender
  Set-MpPreference -DisableRealtimeMonitoring $true
  New-ItemProperty -Path 'hklm:\SOFTWARE\Policies\Microsoft\Windows Defender' -Name "DisableAntiSpyware" -Value 1 -PropertyType "DWORD"
  New-ItemProperty -Path 'hklm:\SOFTWARE\Policies\Microsoft\Windows Defender' -Name "DisableRoutinelyTakingAction" -Value 1 -PropertyType "DWORD"

  # Disable UAC (commented)
  New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\" -Name "EnableLUA" -PropertyType "DWORD" -Value "0" -Force
}

Set-Registry-Values

# Disable windows updates
$RunningAsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if ($RunningAsAdmin)
{

	$Updates = (New-Object -ComObject "Microsoft.Update.AutoUpdate").Settings

	if ($Updates.ReadOnly -eq $True) { Write-Error "Cannot update Windows Update settings due to GPO restrictions." }

	else {
		$Updates.NotificationLevel = 1 #Disabled
		$Updates.Save()
		$Updates.Refresh()
		Write-Output "Automatic Windows Updates disabled."
	}
} else {
  Write-Warning "Must be executed in Administrator level shell."
	Write-Warning "Script Cancelled!" 
}

Install-PackageProvider -Name Nuget -Force
Install-Module PSWindowsUpdate -Force
Add-WUServiceManager -ServiceID 7971f918-a847-4430-9279-4a52d1efe18d -Confirm:$False

Write-Host "Installing doit."

[Environment]::SetEnvironmentVariable("DOIT_SERVER", "localhost", [System.EnvironmentVariableTarget]::Machine)
[Environment]::SetEnvironmentVariable("HOME", "C:\Users\vagrant", [System.EnvironmentVariableTarget]::Machine)

# https://stackoverflow.com/questions/25407634/check-processor-architecture-and-proceed-with-if-statement
if ([System.Environment]::Is64BitProcess) {
  Copy-Item a:\doitclient_x64.exe C:\Windows\doitclient.exe
  Copy-Item a:\doit_x64.exe C:\Windows\doit.exe
} else {
  Copy-Item a:\doitclient_x86.exe C:\Windows\doitclient.exe
  Copy-Item a:\doit_x86.exe C:\Windows\doit.exe
}

Copy-Item a:\doit-secret C:\Windows
Copy-Item a:\doitrc C:\Users\vagrant\.doitrc
Copy-Item a:\do.ps1 C:\Windows
Copy-Item a:\doit-server.bat "C:\Users\vagrant\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
Copy-Item a:\mount-drive.bat "C:\Users\vagrant\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"

netsh advfirewall firewall add rule name="Allow DoIt server" dir=in action=allow program="C:\Windows\doit.exe"
netsh advfirewall firewall add rule name="Allow DoIt client" dir=out action=allow program="C:\Windows\doitclient.exe"
