#-------------------------------------------------------------------------
# Copyright (c) 2014 Microsoft Corporation. All rights reserved.
# Use of this sample source code is subject to the terms of the Microsoft license 
# agreement under which you licensed this sample source code and is provided AS-IS.
# If you did not accept the terms of the license agreement, you are not authorized 
# to use this sample source code. For the terms of the license, please see the 
# license agreement between you and Microsoft.
#-------------------------------------------------------------------------

$script:ErrorActionPreference = "Stop"
$domain = .\Get-ConfigurationPropertyValue.ps1 Domain
$userName = .\Get-ConfigurationPropertyValue.ps1 UserName
$password = .\Get-ConfigurationPropertyValue.ps1 Password
$computerName = .\Get-ConfigurationPropertyValue.ps1 SutComputerName

$requestUrl = .\Get-ConfigurationPropertyValue.ps1 RequestUrl

$securePassword = $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$credential = new-object Management.Automation.PSCredential(($domain+"\"+$userName),$securePassword)

#invoke function remotely
$ret = invoke-command -computer $computerName -Credential $credential -scriptblock {
  param(
       [string]$listName,
       [string]$fileName,
       [string]$requestUrl
  )
  $script:ErrorActionPreference = "Stop"
  [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint");
  try
  {
      $spSites = new-object Microsoft.SharePoint.SPSite $requestUrl;
      $spWeb =  $spSites.openweb()
      $File = $spWeb.GetFolder($listName).Files[$fileName];
      $fileVersions = $File.Versions;
      [string]$versions = "";
      if($fileVersions.Count -ne "0")
      {
          $versions = $versions + $fileVersions[0].VersionLabel;
          $versions = $versions + "^";
      }
      else
      {
          return "@" + $File.UIVersionLabel;
      }
      for($i = 1; $i -le $fileVersions.Count - 1; $i++)
      {
          $versions = $versions + $fileVersions[$i].VersionLabel;
          $versions = $versions + "^";
      }
      $versions = $versions + "@" + $File.UIVersionLabel;
  }
  catch
  {
      throw $error[0]
  }
  finally
  {
      if($spSites -ne $null)
      {
          $spSites.Dispose()
      }
  }
  return $versions
} -argumentlist $listName, $fileName, $requestUrl

return $ret