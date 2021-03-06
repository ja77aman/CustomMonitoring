#####################################################################################
# Script: WindowsStabilityIndex
# Description: Finds the most recent Windows Stability Index reading and places it
#              in the root\cimv2\Ncentral WMI namespace. This script is meant to be 
#              used in conjunction with the Windows Stability Index custom service.
# Author: Chris Reid
# Date: Feb 10th, 2012
# Version: 1.0
#####################################################################################


# Version History

# 1.0 - Initial Release (Feb. 10th, 2012)



# Declare a few variables that we'll use later on in the script
$Namespace = "NCentral"
$Class = "WindowsStabilityIndex"



#Grab the most recent Stability Index reading from the Win32_ReliabilityStabilityMetrics WMI class. The Format-Table command hides the table headers - all this script needs is the value, not any of the surrounding text
$StabilityIndex = Get-Wmiobject Win32_ReliabilityStabilityMetrics -property @("SystemStabilityIndex") | Select-Object -first 1 {$_.SystemStabilityIndex} | Format-Table -HideTableHeaders | Out-String

# The first command gave an output that is a string value; we need to convert this to a decimal value before we drop it into WMI.
$StabilityIndex = [System.Convert]::ToDecimal($StabilityIndex)
write-host "The Stability Index is: " $StabilityIndex



# Check to see if the root\cimv2\Ncentral WMI namespace exists - if it doesn't, then let's create it
# Thanks to http://gallery.technet.microsoft.com/scriptcenter/d230c216-9d21-4130-a190-4049ca2df21c for the code
If (Get-WmiObject -Namespace "root\cimv2" -Class "__NAMESPACE" | Where-Object {$_.Name -eq $Namespace})
{
    WRITE-HOST "The root\cimv2\Ncentral WMI namespace exists."
}
Else
{
    WRITE-HOST "The root\cimv2\Ncentral WMI namespace does not exist."
    $wmi= [wmiclass]"root\cimv2:__Namespace" 
    $newNamespace = $wmi.createInstance() 
    $newNamespace.name = $Namespace 
    $newNamespace.put() 
}






# Check to see if the 'WindowsStabilityIndex' class exists - if it doesn't, then let's create it
If (Get-WmiObject -List -Namespace "root\cimv2\Ncentral" | Where-Object {$_.Name -eq $Class})
{
    WRITE-HOST "The " $Class " WMI class exists."
    # Because the class already exists, we need to make sure it's 'blank', and does not contain any pre-populated instances
    # Hint: Pre-populated instances could have come from someone having already run this script.
    $GetExistingInstances = Get-WmiObject -Namespace "root\cimv2\Ncentral" -Class $Class
	WRITE-HOST $GetExistingInstances
    If ($GetExistingInstances -eq $Null) 
    {
        WRITE-HOST "There are no instances in this WMI class."         
    }
    Else
    {
        WRITE-HOST "There are pre-existing instances of this WMI class - deleting."
        ForEach ($Instance in $GetExistingInstances) {Remove-WMIObject -Namespace "root\cimv2\Ncentral" -Class $Class}
    }
}

    WRITE-HOST "The " $Class " WMI class does need to be created."
    # Because the class doesn't exist (or has just been deleted), let's create it, and specify all of the appropriate properties.
    $subClass = New-Object System.Management.ManagementClass ("root\cimv2\Ncentral", [String]::Empty, $null); 
    $subClass["__CLASS"] = $Class; 
    $subClass.Qualifiers.Add("Static", $true)
    $subClass.Properties.Add("Name", [System.Management.CimType]::String, $false)
    $subClass.Properties["Name"].Qualifiers.Add("Key", $true)
    $subClass.Properties.Add("StabilityIndex", [System.Management.CimType]::Real64, $false)
    $subClass.Put()


# Now let's push the backup data into WMI
$PushDataToWMI = ([wmiclass]"root\cimv2\Ncentral:WindowsStabilityIndex").CreateInstance()
$PushDataToWMI.Name =  "Stability Data"
$PushDataToWMI.StabilityIndex = $StabilityIndex
$PushDataToWMI.Put()
