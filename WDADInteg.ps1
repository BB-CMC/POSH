<#
.Synopsis
WD Integration
.DESCRIPTION
Downloads csv files, uses simple queue, finds and updates
.NOTES
Add error handling around temp failures(tm)
#>
# declare Functions
Filter Filter-ForestUsers
{
if ($_.'GENERAL-Company' -like "CU8 Cabot Microelectronics Corporation" ) { $_ }
if ($_.'GENERAL-Company' -like "CMC International") { $_ }
}
function Process-Workday
{
param([string]$file)
$filepath = "sso/" + $file
$users = @()
$usersfiltered = @()
$users = import-csv -Path $filepath
[Array]$usersfiltered = [Array]$users | Filter-ForestUsers
foreach ($user in $usersfiltered) 
{ 
$adusername = $null
$username = ""
write-host $username "-" $user.'GENERAL-AD User Name' "-" $user.'GENERAL-WD User Name'
$email = $user.'GENERAL-WD User Name'
[Array]$aduser = Get-ADUser -Filter {EmailAddress -like $email} -Properties EmailAddress
switch($aduser.count){
0 {
"Nobody with email found:" + $email | out-file -Append -FilePath .\error.txt
}
Default { 
"Too many users found duplicates:" + $email | out-file -Append -FilePath .\error.txt
} 
1 { 
if($aduser[0].SamAccountName -ne $username){
"Username to email mismatch " + $aduser[0].SamAccountName + " " + $username + " " + $user.'GENERAL-E-mail' + " " + $aduser[0].emailaddress | out-file -Append -FilePath .\error.txt
}

# update user
$adusername = $aduser[0]
$adusername | Set-ADUser -Replace @{extensionAttribute4="SN"}
if($user.'GENERAL-Preferred First Name' -ne "") { $adusername | Set-ADUser -Givenname $user.'GENERAL-Preferred First Name' } 
if($user.'GENERAL-Preferred Last Name' -ne "") { $adusername | Set-ADUser -Surname $user.'GENERAL-Preferred Last Name' } 
if($user.'GENERAL-Office' -ne "") { $adusername | Set-ADUser -Office $user.'GENERAL-Office' } 
if($user.'GENERAL-E-mail' -ne "") { $adusername | Set-ADUser -EmailAddress $user.'GENERAL-E-mail' } 
if($user.'GENERAL-Business Unit' -ne "") { $adusername | Set-ADUser -Replace @{managerid=$user.'GENERAL-Business Unit'} } 
if($user.'ADDRESS-Street' -ne "") { $adusername | Set-ADUser -StreetAddress $user.'ADDRESS-Street' } 
if($user.'ADDRESS-City' -ne "") { $adusername | Set-ADUser -City $user.'ADDRESS-City' } 
if($user.'ADDRESS-State/province' -ne "") { $adusername | Set-ADUser -State $user.'ADDRESS-State/province' } 
if($user.'ADDRESS-Zip/Postal Code' -ne "") { $adusername | Set-ADUser -PostalCode $user.'ADDRESS-Zip/Postal Code' } 
if($user.'ADDRESS-Country/region' -ne "") { $adusername | Set-ADUser -Country $user.'ADDRESS-Country/region' } 
if($user.'ORGANIZATION-Title' -ne "") { $adusername | Set-ADUser -Title $user.'ORGANIZATION-Title' } 
if($user.'ORGANIZATION-Department' -ne "") { $adusername | Set-ADUser -Department $user.'ORGANIZATION-Department' } 
if($user.'ORGANIZATION-Company' -ne "") { $adusername | Set-ADUser -Company $user.'ORGANIZATION-Company' } 
if($user.'HIDDEN-managerid' -ne "") { $adusername | Set-ADUser -Replace @{managerid=$user.'HIDDEN-managerid'} } 
if($user.'HIDDEN-employeeid' -ne "") { $adusername | Set-ADUser -Replace @{employeeid=$user.'HIDDEN-employeeid'} } 
if($user.'TELEPHONE-Mobile' -ne "") { $adusername | Set-ADUser -MobilePhone $user.'TELEPHONE-Mobile' } 
if($user.'GENERAL-Telephone number' -ne "") { $adusername | Set-ADUser -OfficePhone $user.'GENERAL-Telephone number' }
if($user.'GENERAL-Preferred First Name' -ne "" -and $user.'GENERAL-Preferred Last Name' -ne "") 
{ 
$display = $user.'GENERAL-Preferred First Name' + " " + $user.'GENERAL-Preferred Last Name'
$adusername | Set-ADUser -DisplayName $display 
}
if($user.'HIDDEN-managerid' -ne "") 
{
$managerfilter = -join("employeeid -eq ", $user.'HIDDEN-managerid')
$manager = get-aduser -Filter $managerfilter 
$user
$adusername
$manager
write-host "---------------------"
$adusername | Set-ADUser -Manager $manager.samaccountname 
}
if($user.'GENERAL-Active' -eq "Y")
{
$adusername | Set-ADAccountExpiration -DateTime (date)
$adusername | Disable-ADAccount
"Disabling username: " + $email | out-file -Append -FilePath .\log.txt
}

}`
}

}
}
# Do Work
Set-Location C:\scripts\wdinteg
Start-Transcript -path C:\scripts\wdinteg\logtranscript.txt -append
$synccmd = "c:\scripts\wdinteg\pscp.exe -batch workday@198.18.47.146:./sso/AD* sso/"
iex $synccmd
$processedfiles = New-Object System.Collections.ArrayList
foreach ($item in (get-content ".\processedfiles.csv")) { $processedfiles.add($item) } 
$currentfiles = Get-ChildItem -File -Path "c:\scripts\wdinteg\sso" -Filter "*.csv"
foreach ($file in $currentfiles) 
{

if($processedfiles.contains($file.name) -ne $true)
{
write-host "Processing file: " $file.name
Process-Workday -File $file.name
Add-Content ".\processedfiles.csv" $file.name
} 
}

Stop-Transcript
