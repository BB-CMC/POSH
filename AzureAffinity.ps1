Install-Module AzureAD -Force
Import-Module ActiveDirectory
Import-Module AzureAD

    [string]$cAdmin = "brandon_burkhardtadmin@cabotcmp.com"
    [string]$cPass = "./twerp.derp"
    [securestring]$sStringCMC = ConvertTo-SecureString -AsPlainText $cPass -Force
    [pscredential]$cmcCredObj = New-Object System.Management.Automation.PSCredential ($cAdmin, $sStringCMC)

Connect-AzureAD -TenantId "f955a69c-dd03-4f4e-a944-ebbb163d1524" -Credential $cmcCredObj 

$azUsers = Import-Csv -Path "C:\Users\BBURKHARDT\Desktop\AZ_Users.csv"-Header "PersonName"


$bulkInfo = @()
$bulkInfo = $azUsers | ForEach-Object {
    $DisplayName = $_.PersonName
    Get-AzureADUser -SearchString $DisplayName
}

$Users_Report = @()
ForEach($User in $bulkInfo)
	{
		$User_ObjectID = $User.ObjectID	
		$User_DisplayName = $User.DisplayName
		$User_Mail = $User.UserPrincipalName
		$User_Mobile = $User.Mobile
		$User_OU = $User.extensionproperty.onPremisesDistinguishedName
		$User_Account_Status = $User.AccountEnabled
		
		$Get_User_Devices = (Get-AzureADUserRegisteredDevice -ObjectId $User_ObjectID)
		$Count_User_Devices = $Get_User_Devices.count
				
		$User_Owner_Obj = New-Object PSObject
		$User_Owner_Obj | Add-Member NoteProperty -Name "User Name" -Value $User_DisplayName
		$User_Owner_Obj | Add-Member NoteProperty -Name "User Mail" -Value $User_Mail -force	
		$User_Owner_Obj | Add-Member NoteProperty -Name "Devices count" -Value $Count_User_Devices -force
				
		If($Count_User_Devices -eq 0)
			{
				$User_Owner_Obj | Add-Member NoteProperty -Name "Device name" -Value "No device" -force
				$User_Owner_Obj | Add-Member NoteProperty -Name "Device last logon" -Value "No device" -force
				$User_Owner_Obj | Add-Member NoteProperty -Name "Device OS type" -Value "No device" -force
				$User_Owner_Obj | Add-Member NoteProperty -Name "Device OS version" -Value "No device" -force
			}
			
		If($Count_User_Devices -gt 1)
			{
				$Devices_LastLogon = @()
				$Devices_OSType = @()
				$Devices_OSVersion = @()
				$Devices_DisplayName = @()
				
				$Devices_LastLogon = ""
				$Devices_OSType = ""
				$Devices_OSVersion = ""
				$Devices_DisplayName = ""

				ForEach($Device in $Get_User_Devices)
					{
						$Device_LastLogon = $Device.ApproximateLastLogonTimeStamp
						$Device_OSType = $Device.DeviceOSType
						$Device_OSVersion = $Device.DeviceOSVersion
						$Device_DisplayName = $Device.DisplayName
						
						If ($owner -eq $Get_User_Devices[-1])
							{
								$Devices_LastLogon += "$Device_LastLogon" 
								$Devices_OSType += "$Device_OSType"
								$Devices_OSVersion += "$Device_OSVersion"
								$Devices_DisplayName += "$Device_DisplayName"
							}
						Else
							{
								$Devices_LastLogon += "$Device_LastLogon`n" 
								$Devices_OSType += "$Device_OSType`n"
								$Devices_OSVersion += "$Device_OSVersion`n"
								$Devices_DisplayName += "$Device_DisplayName`n"
							}
					}

				$User_Owner_Obj | Add-Member NoteProperty -Name "Device name" -Value $Devices_DisplayName -force
				$User_Owner_Obj | Add-Member NoteProperty -Name "Device last logon" -Value $Devices_LastLogon -force
				$User_Owner_Obj | Add-Member NoteProperty -Name "Device OS type" -Value $Devices_OSType -force	
				$User_Owner_Obj | Add-Member NoteProperty -Name "Device OS version" -Value $Devices_OSVersion -force
			}
		Else		
			{
				$Device_LastLogon = $Get_User_Devices.ApproximateLastLogonTimeStamp
				$Device_OSType = $Get_User_Devices.DeviceOSType
				$Device_OSVersion = $Get_User_Devices.DeviceOSVersion
				$Device_DisplayName = $Get_User_Devices.DisplayName

				$User_Owner_Obj | Add-Member NoteProperty -Name "Device name" -Value $Device_DisplayName -force
				$User_Owner_Obj | Add-Member NoteProperty -Name "Device last logon" -Value $Device_LastLogon -force
				$User_Owner_Obj | Add-Member NoteProperty -Name "Device OS type" -Value $Device_OSType -force	
				$User_Owner_Obj | Add-Member NoteProperty -Name "Device OS version" -Value $Device_OSVersion -force
				
			}
		$Users_report += $User_Owner_Obj
	}
	
$Users_report | out-gridview		
$Users_report| export-csv "CSV_Path\list_Users_Devices.csv" -notype -delimiter ";" 