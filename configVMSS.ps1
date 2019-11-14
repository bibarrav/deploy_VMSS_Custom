param (
    [string]$dUsername,
    [string]$dPassword,
    [string]$dName
)

#Encrypts password of type 'System.Security.SecureString' to encrypted type of 'string'.
$encryptPass = $dPassword | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString

#Get name of Azure Instance, not the same as computer name
$compute = Invoke-RestMethod -Uri "http://169.254.169.254/metadata/instance?api-version=2019-03-11" -Headers @{"Metadata" = "true" }
$computeName = $compute.compute.name

#Set perm system environment variable with name of key vault for cred retrival during scale-in operations
[System.Environment]::SetEnvironmentVariable('dUsername',$dUsername,[System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('dPassword',$encryptPass,[System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('dName',$dName,[System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('azInsName',$computeName,[System.EnvironmentVariableTarget]::Machine)

# Create new self signed cert
$newCert = New-SelfSignedCertificate -dnsname "localhost" -KeyLength 2048 -CertStoreLocation cert:\LocalMachine\My -NotAfter (Get-Date).AddYears(20)
 
# Create https binding for default web site
New-WebBinding -Name "Default Web Site" -IPAddress "*" -Port 443 -Protocol https
 
# Get https binding information in preperation for associating with newly created cert
$binding = Get-WebBinding -Name "Default Web Site" -Protocol https
 
# Associate https binding with cert, done!
$binding.AddSslCertificate($newCert.GetCertHashString(), "my") 

#Create vmss Script directory, download termination script
New-Item -Type directory -Path C:\ -Name vmssScripts -Force
Invoke-WebRequest -Uri https://vmssstor.blob.core.usgovcloudapi.net/vmssmanage/terminateInstance.ps1 -UseBasicParsing -OutFile C:\vmssScripts\terminateInstance.ps1
Unblock-File -Path C:\vmssScripts\terminateInstance.ps1 

# Create scheduled task to check for scale in and take appropriate action
New-Item -Name vmssScripts -ItemType directory -Path C:\
$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -WorkingDirectory 'C:\vmssScripts' -Argument '-NoProfile -WindowStyle Hidden -File terminateInstance.ps1'
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(5) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Start (get-date) -End (get-date).AddYears(20)) 
$principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest 
$settings = New-ScheduledTaskSettingsSet -Compatibility Win8 -StartWhenAvailable -RestartInterval (New-TimeSpan -Minutes 1) -RestartCount 3 -Hidden


Register-ScheduledTask -Action $action -Trigger $trigger -TaskName 'detectTerimination' -Settings $settings -Principal $principal -Force 
