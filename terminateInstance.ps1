
#Function List

function Get-ScheduledEvents($uri) {
    $scheduledEvents = Invoke-RestMethod -Headers @{"Metadata" = "true" } -URI $uri -Method get
    return $scheduledEvents
}
function prepareForTermination {

    #Add code here, system is preparing to be removed from scale set, take all needed actions in this code block.
    
    Get-ScheduledTask -TaskName detectTerimination | Disable-ScheduledTask    
}

##Main Script

#Gather local instance computer name 
$localComputerName = $env:azInsName

# Set up the scheduled events URI for a VNET-enabled VM
$localHostIP = "169.254.169.254"
$scheduledEventURI = 'http://{0}/metadata/scheduledevents?api-version=2019-01-01' -f $localHostIP 

# Get events
$scheduledEvents = Get-ScheduledEvents $scheduledEventURI

#Determine if termination event exists, and if it exists is it applicable to this specific instance
if ($scheduledEvents.Events.Length -ge 1) {
    $termEvents = $scheduledEvents.Events | Where-Object { $_.EventType -eq "Terminate" -and $_.Resources -icontains $localComputerName }
    if ($termEvents) {
        #Get system environment variables in prep for domain unjoin, set during inital deployment/creation of VMSS
        $dUserName = $env:dUsername
        $dPassword = ConvertTo-SecureString $env:dPassword
        $dName = $env:dName

        #Combine domain username and domain name to get fully qualified username
        $dUsernameFQUN = $dUserName + '@' + $dName

        #Create PSCredential Object 
        $dCreds = New-Object System.Management.Automation.PSCredential ($dUsernameFQUN, $dPassword)

        #Custom work to remove instance from loadbalancer, wind down operations so that computer can be removed from domain
        prepareForTermination

        #Remove Computer from domain
        Remove-Computer -UnjoinDomainCredential $dCreds -Restart -Force        
    }   
}

