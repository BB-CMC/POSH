$searchtext = " successfully processed download completion."

$Logpath = Get-ItemProperty -path HKLM:\Software\Microsoft\CCM\Logging\@Global
 $Log = $logpath.LogDirectory
$file = "$Log\ContentTransferManager.log"
if (Test-Path $file){
 if (Get-Content $file | Select-String -Pattern $searchtext -Quiet){
  $StrResult = (Get-Content $file | Select-String -Pattern $searchtext |
   Select -Last 1).ToString()
  $LastCTMid = $StrResult.SubString(1,$StrResult.IndexOf('}')) |
   %{$_.Replace($_.SubString(0,$_.IndexOf('{')),'')}

  $searchtext2 = "CTM job $LastCTMid switched to location "
  $StrResult2 = (Get-Content $file | Select-String -Pattern $searchtext2 -SimpleMatch |
   Select -Last 1).ToString()
  IF($StrResult2){
   $LastDP = $StrResult2.Split('/')[2]}
  ELSE{
  $searchtext3 = "CTM job $LastCTMid (corresponding DTS job {"
  $StrResult3 = (Get-Content $file | Select-String -Pattern $searchtext3 -SimpleMatch |
   Select -Last 1).ToString()
  $LastDP = $StrResult3.Split('/')[2]
}}}
$LastDP

function Wait-KeyPress
{
    param
    (
        [string]
        $exitMessage = 'Press Enter to exit.',


        [ConsoleKey]
        $eKey = [ConsoleKey]::Enter

    )
    
    Write-Host -Object $exitMessage
    
    do
    {
        $keyInfo = [Console]::ReadKey($false)
    } 
    until ($keyInfo.Key -eq $ekey)
    if ($keyInfo.Key -eq $ekey)
    {
        exit
    }
}
Wait-KeyPress