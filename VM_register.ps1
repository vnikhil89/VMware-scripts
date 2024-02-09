Import-Module vmware.powercli
$VCUser = "administrator@vsphere.local"
$VCPWord = ConvertTo-SecureString -String "password" -AsPlainText -Force
$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $VCUser, $VCPWord 
try {                                                                                                              
Connect-VIServer -Server vcenter -Credential $cred 
}
catch {
Write-Output "Failed to connect vcenter"
break
}  
$Datastorename = Read-Host "Enter DatastoreName" 
$Dvswitchname = Read-Host "Enter Dvsswitch Name"
$segmentname =  Read-Host "Enter Segment Name"                                                                                           
$ds =Get-Datastore -Name $Datastorename                                                                             
New-PSDrive -Name tgtds -Location $ds -PSProvider VimDatastore -Root '\' 
$file = Import-Csv .\abc.csv
$vms = $file.Name 
foreach ($vm in $vms){
  try {                                               
     $nv = Get-ChildItem -Path tgtds: -Recurse | ? Name -eq "$vm.vmx"                                                                                                                              
     $h = Get-VMHost                                                                                                                                
     New-VM -VMFilePath $nv.DatastoreFullPath -VMHost $h.Name
     Write-Output "$vm regsitered successfully"
      }
  catch {
    Write-Output "$vm failed to register"
    break
      }                                                                                                              
    $na =(Get-VM -Name $vm).name                                                                                            
    $pgs =Get-VDSwitch -Name $Dvswitchname | Get-VDPortgroup
    foreach ($pg in $pgs.name){
        if ($pg -eq $segmentname){ 
           Write-Output "Segement Found"                                                                                                                                                                                                                                                                                                                                                                                                         
           Get-NetworkAdapter -VM $na | Set-NetworkAdapter -Portgroup $segmentname -Confirm:$false
           Write-Output "VM network change completed"
           Start-VM -VM $vm -Confirm:$false
           }

      }
}

Remove-PSDrive -Name tgtds
Disconnect-VIServer * -Confirm:$false