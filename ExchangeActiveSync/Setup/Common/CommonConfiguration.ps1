#-------------------------------------------------------------------------
# Copyright (c) 2015 Microsoft Corporation. All rights reserved.
# Use of this sample source code is subject to the terms of the Microsoft license 
# agreement under which you licensed this sample source code and is provided AS-IS.
# If you did not accept the terms of the license agreement, you are not authorized 
# to use this sample source code. For the terms of the license, please see the 
# license agreement between you and Microsoft.
#-------------------------------------------------------------------------

#-------------------------------------------------------------------------
# Configuration script exit code definition:
# 1. A normal termination will set the exit code to 0
# 2. An uncaught THROW will set the exit code to 1
# 3. Script execution warning and issues will set the exit code to 2
# 4. Exit code is set to the actual error code for other issues
#-------------------------------------------------------------------------

#-----------------------------------------------------------------------------------
# <summary>
# Throw exception if the required parameter is empty.
# </summary>
# <param name="parameterName">The name of parameter to be checked.</param>
# <param name="parameterValue">The value of parameter to be checked.</param>
#-----------------------------------------------------------------------------------
function ValidateParameter
{
    param(
    [string]$parameterName,
    [string]$parameterValue
    )
    
    if ($parameterValue -eq $null -or $parameterValue -eq "")
    {
        Throw "Parameter $parameterName cannot be empty."
    }    
}

#-----------------------------------------------------------------------------------
# <summary>
# Print the content with the specified color and add the content to the log file. 
# </summary>
# <param name="content">The content to be printed.</param>
# <param name="color">The color of the content.</param>
#-----------------------------------------------------------------------------------
function Output
{
    param(
    [string]$content,
    [string]$color
    )
    
    $timeString = Get-Date -format "yyyy-MM-dd HH:mm:ss"
    $timestampsContent = "[$timeString] $content"
    $content = $content + "`r`n"
    if ($color -eq $null -or $color -eq "")
    {
        Write-Host $content -NoNewline
        Add-Content -Path $logFile -Force -Value $timestampsContent
    }
    else
    {
        Write-Host $content -NoNewline -ForegroundColor $color
        Add-Content -Path $logFile -Force -Value $timestampsContent
    }
}

#-----------------------------------------------------------------------------------
# <summary>
# Color(Green): Successful input and values that are written to PTFConfig. 
# </summary>
# <param name="content">The content to be printed.</param>
#-----------------------------------------------------------------------------------
function OutputSuccess
{
    param(
    [string]$content
    )
	
    Output $content "Green"
}

#-----------------------------------------------------------------------------------
# <summary>
# Color(Yellow): Repeat question for user input or warning.
# </summary>
# <param name="content">The content to be printed.</param>
#-----------------------------------------------------------------------------------
function OutputWarning
{
    param(
    [string]$content
    )
    
    Output $content "Yellow"
}

#-----------------------------------------------------------------------------------
# <summary>
# Color(White): Descriptive, instructive or informative text. 
# </summary>
# <param name="content">The content to be printed.</param>
#-----------------------------------------------------------------------------------
function OutputText
{
    param(
    [string]$content
    )
    
    Output $content "White"
}

#-----------------------------------------------------------------------------------
# <summary>
# Color(Cyan): Question requiring user input.
# </summary>
# <param name="content">The content to be printed.</param>
#-----------------------------------------------------------------------------------
function OutputQuestion
{
    param(
    [string]$content
    )
    
    Output $content "Cyan"
}

#-----------------------------------------------------------------------------------
# <summary>
# Color(Red): User input error or script error.
# </summary>
# <param name="content">The content to be printed.</param>
#-----------------------------------------------------------------------------------
function OutputError
{
    param(
    [string]$content
    )
    
    Output $content "Red"
}

#-----------------------------------------------------------------------------------
# <summary>
# Modify the value of the specific node in the specific ptfconfig file.
# </summary>
# <param name="sourceFileName">The name of the configuration file containing the node.</param>
# <param name="nodeName">The name of the node.</param>
# <param name="nodeValue">The new content of the node.</param>
#-----------------------------------------------------------------------------------
function ModifyConfigFileNode
{
    Param(
    [string]$sourceFileName, 
    [string]$nodeName, 
    [string]$nodeValue
    )

    #----------------------------------------------------------------------------
    # Parameter validation
    #----------------------------------------------------------------------------
    ValidateParameter 'sourceFileName' $sourceFileName
    ValidateParameter 'nodeName' $nodeName

    #----------------------------------------------------------------------------
    # Modify the content of the node
    #----------------------------------------------------------------------------
    $isFileAvailable = $false
    $isNodeFound = $false

    $isFileAvailable = Test-Path $sourceFileName
    if($isFileAvailable -eq $true)
    {    
        [xml]$configContent = New-Object XML
        $configContent.Load($sourceFileName)
        $propertyNodes = $configContent.GetElementsByTagName("Property")
        foreach($node in $propertyNodes)
        {
            if($node.GetAttribute("name") -eq $nodeName)
            {
                $node.SetAttribute("value",$nodeValue)
                $isNodeFound = $true
                break
            }
        }
        
        if($isNodeFound)
        {
            $configContent.save($sourceFileName)
        }
        else
        {
            Throw "Configuration file $sourceFileName error : Cannot find node with the name attribute $nodeName while modifying its value." 
        }
    }
    else
    {
        Throw "Configuration file $sourceFileName error : File does not exist!" 
    }

    #----------------------------------------------------------------------------
    # Verify the result
    #----------------------------------------------------------------------------
    if($isFileAvailable -eq $true -and $isNodeFound)
    {
        [xml]$configContent = New-Object XML
        $configContent.Load($sourceFileName)
        $propertyNodes = $configContent.GetElementsByTagName("Property")
        foreach($node in $propertyNodes)
        {
            if($node.GetAttribute("name") -eq $nodeName)
            {
                if($node.GetAttribute("value") -eq $nodeValue)
                {
                    OutputSuccess "[ModifyConfigFileNode] success: Set $nodeName to $nodeValue"
                    return
                }
            }
        }

        Throw "Failed after changing the configuration file $sourceFileName : The actual value of the node does not match the updated value."
    }
}

#-----------------------------------------------------------------------------------
# <summary>
# Get installation path
# </summary>
# <param name="registryPaths">The registry path of software.</param>
# <returns>Return installation path if it is available, else return null.</returns>
#-----------------------------------------------------------------------------------
function GetInstalledPath
{
    param(
    [Array]$registryPaths
    )

    #----------------------------------------------------------------------------
    # Parameter validation
    #----------------------------------------------------------------------------
    ValidateParameter 'registryPaths' $registryPaths
    $installPath=$null
    foreach($registryPath in $registryPaths)
    {   if(Test-path $registryPath)
        {
            $application     = Get-Item $registryPath
            $psPath          = Get-ItemProperty $application.PsPath
            if($psPath -ne $null -and $psPath -ne "")
            {
                $installPath  = $psPath.InstallDir
                if($installPath -eq "" -or $installPath -eq $null)
                {
                    $installPath  = $psPath.InstallDir_2010
                }               
                if($installPath -ne "" -and $installPath -ne $null -and (Test-Path $installPath))
                {
                    return $installPath 
                }                
            }
        }
    }
    return $installPath
}

#-----------------------------------------------------------------------------------
# <summary>
# Check whether the machine has installed the Visual Studio
# </summary>
# <param name="recommendVersion">The recommend version of Visual Studio.</param>
# <returns>A Boolean value, true if the Visual Studio has been installed, otherwise false.</returns>
#-----------------------------------------------------------------------------------
Function CheckVSVersion
{
    param(
    [string]$recommendVersion = "10.0"
    )
           
    $versions = @{"9.0" = "Visual Studio 2008";"10.0" = "Visual Studio 2010";"11.0" = "Visual Studio 2012";"12.0" = "Visual Studio 2013"}
    if($versions.Keys -notcontains $recommendVersion)
    {
        Throw "Parameter recommendVersion should have one of the following values: $($versions.Keys)!"
    }
    else
    {
        $recommendVersion = $versions[$recommendVersion]
    }
    $installedVersions = @()
    $installed = $false
    foreach($version in $versions.Keys)
    {  
        $registryPaths = "HKLM:\SOFTWARE\Microsoft\VisualStudio\$version", "HKLM:\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\$version"
        $installPath = GetInstalledPath $registryPaths
        if($installPath -ne $null)
        {
            $installedVersions += $versions[$version]
        }  
    }   
    
    if($installedVersions)
    {        
        if($installedVersions -contains "$recommendVersion")
        {
            OutputSuccess "The application $recommendVersion is installed."
            $installed = $true
        }
        else
        {   
            $flag = @{$true="are";$false="is"}[$installedVersions.Count -gt 1]
            $outPutWord = @()
            foreach($installedVersion in $installedVersions)
            {
                $outPutWord +=$installedVersion+","
            }
            $outPutWord[($outPutWord.Count)-1] = $outPutWord[($outPutWord.Count)-1].split(",")[0]
            OutputWarning ("""" + $outPutWord + """ $flag not the recommended version. Please install $recommendVersion.")
        }        
   } 
   else
   {
       OutputWarning "The application $recommendVersion is not installed"
   }
   
   Return $installed
   
}

#-----------------------------------------------------------------------------------
# <summary>
# Check whether the machine has installed the Protocol Test Framework
# </summary>
# <param name="recommendVersion">The recommend version of Protocol Test Framework.</param>
# <returns>A Boolean value, true if the Protocol Test Framework has been installed, otherwise false.</returns>
#-----------------------------------------------------------------------------------
Function CheckPTFVersion
{
    param(
    [string]$recommendVersion = "1.0.1128.0"
    )
    # The applications to be checked.
    $applicationName = "Protocol Test Framework"
    $registryPaths = "HKLM:\SOFTWARE\Microsoft\ProtocolTestFramework", "HKLM:\SOFTWARE\Wow6432Node\Microsoft\ProtocolTestFramework"
    $applicationInstallPath= GetInstalledPath $registryPaths
    
    $installed = $false
    if($applicationInstallPath -ne $null)
    {
        $dllPaths = [System.IO.Directory]::GetFiles($applicationInstallPath,"Microsoft.Protocols.TestTools.dll",[System.IO.SearchOption]::AllDirectories)
        if($dllPaths -ne "" -and $dllPaths -ne $null)
        {
            if($dllPaths -is [array])
            {
                $dllPath = $dllPaths[0]
            }
            else
            {
                $dllPath = $dllPaths
            }
        }
        $versionInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($dllPath)
        if($versionInfo.ProductMajorPart -eq $recommendVersion.Split(".")[0] -and $versionInfo.ProductMinorPart -eq $recommendVersion.Split(".")[1] -and $versionInfo.ProductBuildPart -ge $recommendVersion.Split(".")[2])
        {
            $installed = $true
        }
                  
    }
            
    # Output the installed status.
    if($installed)
    {
        OutputSuccess ("The required application $applicationName with version " +$versionInfo.ProductVersion+ " is installed.")
    }
    else
    {
		if($versionInfo -ne "" -and $versionInfo -ne $null)
		{
        	OutputWarning ("The installed version of $applicationName is: " +$versionInfo.ProductVersion+ ".")   
    	}
		else
		{
			OutputWarning ("The required application $applicationName is not installed.")
		}
		OutputWarning ("Please install application $applicationName with required version $recommendVersion or a newer one.")
	}
    
    return $installed
       
}

#-----------------------------------------------------------------------------------
# <summary>
# Check whether the machine has installed the Spec Explorer
# </summary>
# <param name="recommendVersion">The recommend version of Spec Explorer.</param>
# <returns>A Boolean value, true if the Spec Explorer has been installed, otherwise false.</returns>
#-----------------------------------------------------------------------------------
Function CheckSEVersion
{
    param(
    [string]$recommendVersion
    )
    # The applications to be checked.
    $applicationName = "Spec Explorer"
    $registryPaths = "HKLM:\SOFTWARE\Microsoft\SpecExplorerVS", "HKLM:\SOFTWARE\Wow6432Node\Microsoft\SpecExplorerVS"
    $applicationInstallPath= GetInstalledPath $registryPaths
    
    $installed = $false
    if($applicationInstallPath -ne $null)
    {
        $dllPaths = [System.IO.Directory]::GetFiles($applicationInstallPath,"Microsoft.SpecExplorer.Core.dll",[System.IO.SearchOption]::AllDirectories)
        if($dllPaths -ne "" -and $dllPaths -ne $null)
        {
            if($dllPaths -is [array])
            {
                $dllPath = $dllPaths[0]
            }
            else
            {
                $dllPath = $dllPaths
            }
        }
        $versionInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($dllPath)
        if($versionInfo.ProductMajorPart -eq $recommendVersion.Split(".")[0] -and $versionInfo.ProductMinorPart -eq $recommendVersion.Split(".")[1])
        {
            $installed = $true
        }
                  
    }
            
    # Output the installed status.
    if($installed)
    {
        OutputSuccess ("The required application $applicationName with version " +$versionInfo.ProductVersion+ " is installed.")
    }
    else
    {
		if($versionInfo -ne "" -and $versionInfo -ne $null)
		{
        	OutputWarning ("The installed version of $applicationName is: " +$versionInfo.ProductVersion+ ".")    
    	}
		else
		{
			OutputWarning ("The required application $applicationName is not installed.") 
		}
		OutputWarning ("Please install application $applicationName with required version $recommendVersion or a newer one.") 
	}
    
    return $installed
       
}

#-----------------------------------------------------------------------------------
# <summary>
# Get user input by manually input or by reading unattended configuration XML.
# </summary>
# <param name="nodeName">Property name in unattended configuration XML.</param>
# <returns>
# user input or value read from XML.
# </returns>
#-----------------------------------------------------------------------------------
function GetUserInput
{
    param(
    [string]$nodeName
    )
    [string]$userInput = ""
    if($unattendedXmlName -eq "" -or $unattendedXmlName -eq $null)
    {
        $userInput = Read-Host
    }
    else
    {
        $isNodeFound = $false
        [xml]$xmlContent = New-Object XML
        $xmlContent.Load($unattendedXmlName)
        $propertyNodes = $xmlContent.GetElementsByTagName("Property")
        foreach($node in $propertyNodes)
        {
            if($node.name -eq $nodeName)
            {
                $userInput = $node."value"
                $isNodeFound = $true
                OutputText "$userInput is the value of the property $nodeName. This value is defined in the configuration XML file." 
                break
            }
        }        
        if(!$isNodeFound)
        {
            OutputWarning "Could not find node with name attribute $nodeName in the configuration XML: `"$unattendedXmlName`", will use empty value instead." 
        }
    }
    return $userInput
}

#-----------------------------------------------------------------------------------
# <summary>
# Check user input that should not be empty. 
# </summary>
# <param name="property">Property name that requires user to input the value.</param>
# <param name="nodeName">Property name in unattended configuration XML.</param>
# <returns>
# Valid user input or exit script execution in unattended mode if the value provided in configuration XML is empty.
# </returns>
#-----------------------------------------------------------------------------------
function CheckForEmptyUserInput
{
    param(
    [string]$property,
    [string]$nodeName
    )

    #----------------------------------------------------------------------------
    # Parameter validation
    #----------------------------------------------------------------------------
    ValidateParameter 'property' $property
    
    While(1)
    {
        [String]$userInput = GetUserInput $nodeName
        if($userInput -ne "" -and $userInput -ne $null )
        {
            return $userInput
        }
        else
        {
            OutputWarning """$property"" cannot be empty" 
            if($unattendedXmlName -eq "" -or $unattendedXmlName -eq $null)
            {
                OutputWarning "Try again with a non-empty value." 
            }
            else
            {
                Write-Warning "Change the value of $nodeName in the configuration XML file: `"$unattendedXmlName`" and then run the script again.`r`n"
                Stop-Transcript
                exit 2
            }
        }
     }    
}

#-----------------------------------------------------------------------------------
# <summary>
# Check user's input until it is a valid one. 
# </summary>
# <param name="userChoices">The available number list user can select from.</param>
# <param name="nodeName">Property name in unattended configuration XML.</param>
# <returns>
# The valid number.
# </returns>
#-----------------------------------------------------------------------------------
function ReadUserChoice
{
    param(
    [Array]$userChoices,
    [string]$nodeName
    )

    $isCorrectValue = $false
    While(1)
    {
        [String]$userInput = GetUserInput $nodeName
        foreach($userChoice in $userChoices)
        {
            $userChoiceNo = ([string]$userChoice).split(":")[0]
            if($userChoiceNo -eq $userInput)
            {
                OutputText "Your selection is ""$userChoice""."
                $IsCorrectValue = $true
                return $userInput
            }    
        } 
        if(!$isCorrectValue)
        {
            OutputWarning """$userInput"" is not a correct input." 
            if($unattendedXmlName -eq "" -or $unattendedXmlName -eq $null)
            {
                OutputWarning "Retry with a correct number from the values listed." 
            }
            else
            {
                Write-Warning "Change the value of $nodeName in the configuration XML file: `"$unattendedXmlName`" with the values listed and then run the script again.`r`n"
                Stop-Transcript
                exit 2
            }   
        }
    }
}

#-----------------------------------------------------------------------------------
# <summary>
# Check if the operating system (OS) version of the specific computer is the recommended Windows 7 SP1/Windows 2008 R2 SP1 and above.
# </summary>
# <param name="computer">The computer name of the machine to be checked.</param>
#-----------------------------------------------------------------------------------
Function CheckOSVersion($computer)
{
    $os = Get-WmiObject -class Win32_OperatingSystem -computerName $computer
    if([int]$os.BuildNumber -ge 7601) 
    {
        OutputSuccess "You are using the recommended operating system."
    }
    else
    {
        OutputWarning "Your operating system is not the recommended version, the recommended operating system is Windows 7 SP1/Windows 2008 R2 SP1 and above." 
        OutputQuestion "Would you like to continue to run the test suite on this machine or exit?" 
        OutputQuestion "1: CONTINUE." 
        OutputQuestion "2: EXIT." 
        $runOnNonRecommendedOSChoices = @('1: CONTINUE','2: EXIT')
        $runOnNonRecommendedOS = ReadUserChoice $runOnNonRecommendedOSChoices "runOnNonRecommendedOS"
        if($runOnNonRecommendedOS -eq "2")
        {
            Stop-Transcript
            exit 0
        }
    }
}

#-----------------------------------------------------------------------------------
# <summary>
# Add timestamp information to the log file. 
# </summary>
# <param name="startOrEndFlag">It is a flag to identify start time or end time.</param>
# <param name="logFile">The path of the log file.</param>
#-----------------------------------------------------------------------------------
function AddTimesStampsToLogFile
{
    param(
    [string]$startOrEndFlag,
    [string]$logFile
    )

    #----------------------------------------------------------------------------
    # Parameter validation
    #----------------------------------------------------------------------------
    ValidateParameter 'startOrEndFlag' $startOrEndFlag
    ValidateParameter 'logFile' $logFile
    
    $timeString = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $userName = $env:USERNAME
    if($env:USERDOMAIN)
    {
        $userName = $env:USERDOMAIN +"\"+$env:USERNAME
    }
    $fileName = Split-Path $logFile -Leaf
    "**********************" | Out-File -FilePath $logFile -Append -Encoding ASCII
    "$fileName $startOrEndFlag" | Out-File -FilePath $logFile -Append -Encoding ASCII
    "$startOrEndFlag" + " time:"+"$timeString" | Out-File -FilePath $logFile -Append -Encoding ASCII
    "UserName :" + $userName | Out-File -FilePath $logFile -Append -Encoding ASCII
    "Machine Name:" + $env:COMPUTERNAME | Out-File -FilePath $logFile -Append -Encoding ASCII
    "**********************" | Out-File -FilePath $logFile -Append -Encoding ASCII
}

#-----------------------------------------------------------------------------------
# <summary>
# Set user's password never expires. 
# </summary>
# <param name="userName">The user name whose password will be set as never-expired.</param>
#-----------------------------------------------------------------------------------
function SetPasswordNeverExpires
{
    param(
    [string]$userName
    )
    
    #----------------------------------------------------------------------------
    # Parameter validation
    #----------------------------------------------------------------------------
    ValidateParameter 'userName' $userName

    try
    {
        $context = new-object System.DirectoryServices.AccountManagement.PrincipalContext("Domain") 
        $userPrincipal = [System.DirectoryServices.AccountManagement.UserPrincipal]::FindByIdentity($context,$userName)
        $userPrincipal.PasswordNeverExpires = $true
        $userPrincipal.save()
        OutputSuccess "The password is set to never expire for user $userName."
    }
    catch [Exception]
    {
        throw $_.Exception.Message
    }
}

#-----------------------------------------------------------------------------------
# <summary>
# Create a user on domain controller.
# </summary>
# <param name="username">The name of the user to be created.</param>
# <param name="password">The password of the user to be created.</param>
#-----------------------------------------------------------------------------------
function CreateUserOnDC
{
    Param(
    [String]$username,
    [String]$password
    )
          
    #----------------------------------------------------------------------------
    # Validate parameter.
    #----------------------------------------------------------------------------
    ValidateParameter 'username' $username
    ValidateParameter 'password' $password
    
    #----------------------------------------------------------------------------
    # Check if the specific user exists. If not, create the user.
    #----------------------------------------------------------------------------
    Invoke-Command{
    
       $ErrorActionPreference = "Continue"
       cmd /c net user /domain $username 2>&1 | Out-Null
       if (!$?)
       {
           cmd /c net user /domain $username $password /add 2>&1 | Out-Null
           if (!$?)
           {
               Throw "Failed to create user $username."
           }
           else
           {
               OutputSuccess "[CreateUserOnDC] User $username has been created."
               #Call function SetPasswordNeverExpires to configure user password as never-expire.
               SetPasswordNeverExpires $username
           }
       }
       else
       {
           OutputWarning "[CreateUserOnDC] User $username already exists. Make sure the password is ""$password""." 
          
           #Call function SetPasswordNeverExpires to configure user password as never-expire.
           SetPasswordNeverExpires $username
       }
       
    }
}

#-----------------------------------------------------------------------------------------------------
# <summary>
# Check if the user already exists in the specified group.
# </summary>
# <param name="userName">The name of the user.</param>
# <param name="groupName">The name of the group that will be checked whether containing the user.</param>
# <returns>
# Return true if the user already exists in the specified group.
# Return false if the user does not exist in the specified group.
# </returns>
#------------------------------------------------------------------------------------------------------
Function CheckGroupMember
{
    param(
    [string]$userName,
    [string]$groupName
    )

    #----------------------------------------------------------------------------
    # Parameter validation
    #----------------------------------------------------------------------------
    ValidateParameter 'userName' $userName
    ValidateParameter 'groupName' $groupName
    
    $groupMembers = Get-WmiObject -Class Win32_GroupUser |where{$_.GroupComponent -like "*$groupName*"}
    if(($groupMembers -ne $null) -and ($groupMembers -ne ""))
    {
        foreach($groupMemberInfo in $groupMembers)
        {
            #An example value of $groupMember is "\\sutComputerName\root\cimv2:Win32_UserAccount.Domain="contoso",Name=$userName"
            $groupMember= $groupMemberInfo.PartComponent
            if((($groupMember.Split(",")[1]).remove(0,5)).replace('"',"") -eq $userName)
            {
                return $true
            } 
        }    
    }
    
    return $false
}

#----------------------------------------------------------------------------------
# <summary>
# Add user to the specified group.
# </summary>
# <param name="domain">A string that specifies the name of the domain.</param>
# <param name="userName">The name of the user.</param>
# <param name="groupName">The name of group that the user will be added to.</param>
#-----------------------------------------------------------------------------------
function AddUserToGroup
{
    param(
    [string]$ADUser,
    [string]$groupName
    )
	
    if(($ADUser -eq $null) -or ($ADUser -eq ""))
    {
        throw "Parameter ADUser cannot be empty"
    }
    if(($groupName -eq $null) -or ($groupName -eq ""))
    {
        throw "Parameter groupName cannot be empty"
    }
	
    $userName=($ADUser.split("\"))[1]
    $exist =CheckGroupMember $userName $groupName
    
    if($exist)
    {
        Output "User $userName is already a member of Group $groupName." "Yellow"
    }
    else
    {
        cmd /c net.exe localgroup $groupName $ADUser /add
		
        $check =CheckGroupMember $userName $groupName
        if($check)
        {
            Output "$userName was added to $groupName group successfully." "Green"
        }
        else
        {
            Throw("Failed to add user $userName to Group $groupName!")
        }
    }
}

#-----------------------------------------------------------------------------------
# <summary>
# Read the value of the specific node in the specific ptfconfig file.
# </summary>
# <param name="sourceFileName">The name of the configuration file containing the node.</param>
# <param name="nodeName">The name of the node.</param>
# <returns>The value of the specific node in the specific ptfconfig file.</returns> 
#-----------------------------------------------------------------------------------
function ReadConfigFileNode
{
    Param(
    [string]$sourceFileName, 
    [string]$nodeName
    )

    #----------------------------------------------------------------------------
    # Parameter validation
    #----------------------------------------------------------------------------
    ValidateParameter 'sourceFileName' $sourceFileName
    ValidateParameter 'nodeName' $nodeName

    #----------------------------------------------------------------------------
    # Read the content of the node
    #----------------------------------------------------------------------------
    $isFileAvailable = $false
    $isNodeFound = $false

    $isFileAvailable = Test-Path $sourceFileName
    if($isFileAvailable -eq $true)
    {   
        [xml]$configContent = New-Object XML
        $configContent.Load($sourceFileName)
        $propertyNodes = $configContent.GetElementsByTagName("Property")
        foreach($node in $propertyNodes)
        {
            if($node.GetAttribute("name") -eq $nodeName)
            {
                return $node.GetAttribute("value")
            }
        }        
        if(!$isNodeFound)
        {
            Throw "Configuration file node read error: Cannot find node with the name attribute $nodeName" 
        }
    }
    else
    {
        Throw "Configuration file node read error: The configuration file $sourceFileName does not exist!"
    }
}

#-----------------------------------------------------------------------------------
# <summary>
# Read computer name from user input. 
# </summary> 
# <param name="allowEmpty">This parameter indicates whether user input can be empty.</param>
# <param name="nodeName">Property name in unattended configuration XML.</param> 
# <returns>
# The valid computer name.
# </returns>
#-----------------------------------------------------------------------------------
function ReadComputerName
{
    param(
    [bool]$allowEmpty,
    [string]$nodeName
    )
    While(1)
    {
        #[String]$computerName = Read-Host 
        [String]$computerName = GetUserInput $nodeName
        if($allowEmpty -and $computerName -eq "")
        {
            return ''
        }
        if($computerName -as [ipaddress])
        {
            OutputWarning "The specified IP address is not supported." 
        }
        elseif($computerName -imatch '[`~!@#$%^&*()=+_\[\]{}\\|;:.''",<>/?]')
        {
            OutputWarning """$computerName"" contains characters that are not allowed. Characters that are not allowed include `` ~ ! @ # $ % ^ & * ( ) = + _ [ ] { } \ | ; : . ' "" , < > / and ?." 
        }
        elseif($computerName.Length -lt 1 -or $computerName.Length -gt 15)
        {
            OutputWarning "The computer name should be between 1-15 characters." 
        }
        else
        {
            return $computerName
        }
        if($unattendedXmlName -eq "" -or $unattendedXmlName -eq $null)
        {
            OutputWarning "Retry with a valid computer name." 
        }
        else
        {
            Write-Warning "Change the value of $nodeName with a valid computer name in configuration XML: `"$unattendedXmlName`" and then run the script again.`r`n"
            Stop-Transcript
            exit 2
        }
    }    
}

#-----------------------------------------------------------------------------------
# <summary>
# Get local machine IP address. 
# </summary>
# <param name="ipVersion">IP version of local machine.</param> 
# <returns>
# Specified IP version address.
# </returns>
#-----------------------------------------------------------------------------------
function GetIpAddress
{
    param(
    [string]$ipVersion
    )
    $ipAddress = ipconfig | Select-String $ipVersion
    if($ipAddress -eq $null)
    {
        return ""
    }
    if(($ipAddress.Count -eq $null) -or ($ipAddress.Count -eq 1))
    {
        $ipAddress=$ipAddress.ToString()
        $ipAddress=$ipAddress.Substring($ipAddress.IndexOf(":")+1).Trim()
        OutputText "The $ipVersion address of your local machine is : $ipAddress" 
    }
    else
    {
        $length=$ipAddress.Count
        $availableAddresses = @()
        OutputText "Your local machine has $length $ipVersion addresses which are listed below:" 
        for($i = 0; $i -lt $ipAddress.Count;)
        {
            $IP=$ipAddress[$i].ToString()
            $IP=$IP.Substring($IP.IndexOf(":")+1).Trim()
            $i++
            $availableAddresses += $IP
            OutputText "$i, $IP" 
        }
        OutputQuestion "Select one IP address which can be connected from the Exchange server." 
        if($unattendedXmlName -eq "" -or $unattendedXmlName -eq $null)
        {
            $availableAddressesChoices = @(1..$ipAddress.Count)
            $ipAddressChoice = ReadUserChoice $availableAddressesChoices
            $ipAddress = $availableAddresses[$ipAddressChoice-1]
        }
        else
        {
            $ipAddress = GetUserInput $ipVersion
            if($availableAddresses -notcontains $ipAddress)
            {
                Write-Warning "`"$ipAddress`" is not a valid $ipVersion address. Change the value of $ipVersion with a valid $ipVersion address in the configuration XML file: `"$unattendedXmlName`" and then run the script again.`r`n"
                Stop-Transcript
                exit 2
            }
        }
        OutputText "The selected $ipVersion address is $ipAddress." 
    }
    return $ipAddress
}

#-----------------------------------------------------------------------------------
# <summary>
# Find the *.cer certificate files located on the SUT server's system drive root, and import to local computer's Trusted Root Certification Authorities store.
# </summary>
# <param name="computerName">The computer name of the SUT server.</param>
# <param name="credentialUserName">The user name of the SUT server, must be in the format DOMAIN\User_Alias.</param>
# <param name="credentialPassword">The password of the domain user name.</param>
#-----------------------------------------------------------------------------------
function ImportCertificates
{
    param(
    [string]$computerName,
    [string]$credentialUserName,
    [string]$credentialPassword 
    )

    #----------------------------------------------------------------------------
    # Parameter validation
    #----------------------------------------------------------------------------
    ValidateParameter 'computerName' $computerName
    ValidateParameter 'credentialUserName' $credentialUserName
    ValidateParameter 'credentialPassword' $credentialPassword

    $securePassword = ConvertTo-SecureString $credentialPassword -AsPlainText -Force
    $credential = new-object Management.Automation.PSCredential($credentialUserName,$securePassword)
    $sharedPath = Invoke-Command -ComputerName $computerName -Credential $credential -ErrorAction SilentlyContinue -ScriptBlock {
        $sysDrive = $env:SystemDrive
        $sysDriveSharedName = $sysDrive.Replace(":", "$")
        $path = "\\" + $env:COMPUTERNAME + "\" + $sysDriveSharedName
        if(!(Test-Path $path))
        {
            cmd /c net share $sysDriveSharedName=$sysDrive`\ | Out-Null
        }
        if(@(Get-ChildItem $path -Include *.cer).Count -ge 1)
        { 
            return $path
        }        
    }
    if($sharedPath -eq "" -or $sharedPath -eq $null)
    {
        OutputError "Cannot find certificate files on $computerName's system root directory. Locate and manually import certificate files to the local computer's Trusted Root Certification Authorities store." 
        OutputWarning "Use the following command to import the certificate files:" 
        OutputWarning "    certutil.exe -addstore Root InFile" 
        OutputWarning "    InFile -- Certificate or CRL file to add to store." 
        cmd /c pause
    }
    else
    {
        OutputText "Import certificate files from $computerName's system root directory to the local computer's Trusted Root Certification Authorities store." 
        cmd /c net use $sharedPath $credentialPassword /user:$credentialUserName| Out-File -FilePath $logFile -Append -encoding ASCII -width 100
        Get-ChildItem $sharedPath -Include *.cer | ForEach-object -Process {cmd /c certutil.exe -addstore Root $sharedPath\$($_.Name)}| Out-File -FilePath $logFile -Append -encoding ASCII -width 100
        cmd /c net use $sharedPath /d /y| Out-File -FilePath $logFile -Append -encoding ASCII -width 100
        OutputSuccess "Imported certificate files from $computerName's system root directory to the local computer's Trusted Root Certification Authorities store successfully."
    }
}

#-----------------------------------------------------------------------------------
# <summary>
# Install Windows feature.
# </summary>
# <param name="featureName">Windows feature name to be installed</param>
#-----------------------------------------------------------------------------------
function InstallWindowsFeature
{
    param(
    [string]$featureName 
    )

    #----------------------------------------------------------------------------
    # Parameter validation
    #----------------------------------------------------------------------------
    ValidateParameter 'featureName' $featureName

    Import-Module ServerManager
    $installStatus = Get-WindowsFeature -Name $featureName
    if($installStatus.Installed -eq $true)
    {
        OutputWarning "Windows feature $featureName is already installed." 
    }
    else
    {   
        $installStatus = Add-WindowsFeature -Name $featureName
        if($installStatus.Success -eq $true)
        {
            OutputSuccess "Windows feature $featureName is installed successfully."
        }
        else
        {
            Throw "Failed to install Windows feature $featureName."
        }
    }
}

#-----------------------------------------------------------------------------------
# <summary>
# Add a firewall inbound rule that allows local port to receive TCP/UDP data.
# </summary>
# <param name="ruleName">Firewall inbound rule Name to be added</param>
# <param name="protocol">Protocol name whose network traffic you want to filter with this firewall rule</param>
# <param name="localPort">The port on the computer on which the firewall profile is applied</param>
# <param name="ruleEnabled">Indicates whether this firewall rule is enabled</param>
#-----------------------------------------------------------------------------------
function AddFirewallInboundRule
{
    param(
    [string]$ruleName,
    [string]$protocol,
    [string]$localPort,
    [bool]$ruleEnabled
    )

    #----------------------------------------------------------------------------
    # Parameter validation
    #----------------------------------------------------------------------------
    ValidateParameter 'ruleName' $ruleName
    ValidateParameter 'protocol' $protocol
    ValidateParameter 'localPort' $localPort
    ValidateParameter 'ruleEnabled' $ruleEnabled

    OutputText "Add a firewall rule `"$ruleName`" to allow local port $localPort to receive $protocol data." 
    Switch ($protocol)
    {
        "UDP" { $protocol = 17; break }
        "TCP" { $protocol = 6; break }
    }
    $firewallPolicy = New-Object -ComObject hnetcfg.fwpolicy2 
    $newRule = New-Object -ComObject HNetCfg.FWRule
    $newRule.Name = $ruleName #Rule display name
    $newRule.Protocol = $protocol
    $newRule.LocalPorts = $localPort 
    $newRule.Enabled = $ruleEnabled
    $isRuleAdded = $false
    foreach($rule in $firewallPolicy.Rules)
    {
        if(($rule.Name -eq $newRule.Name) -and ($rule.Protocol -eq $newRule.Protocol) -and ($rule.LocalPorts -eq $newRule.LocalPorts) -and ($rule.Enabled -eq $newRule.Enabled))
        {
            OutputWarning "The firewall rule `"$ruleName`" is already added" 
            $isRuleAdded = $true
            break
        }
    }
    if(!$isRuleAdded)
    {
        $firewallPolicy.Rules.Add($newRule)
        OutputSuccess "A firewall rule `"$ruleName`" is added."
    }

}

#-----------------------------------------------------------------------------------
# <summary>
# Start specified services.
# </summary>
# <param name="serviceName">Service name needed to be started. Wildcards are allowed.</param>
# <param name="startMode">Start mode of the specified services needed to be started.It could be left empty and will be used only when param serviceName contains wildcards.</param>
# <param name="serviceDisplayName">Service display name of the specified services needed to be started.It will be used only when param serviceName contains wildcards.</param>
#-----------------------------------------------------------------------------------
function StartService
{
    param(
    [string]$serviceName,
    [string]$startMode,
    [string]$serviceDisplayName = "*" 
    )

    #----------------------------------------------------------------------------
    # Parameter validation
    #----------------------------------------------------------------------------
    ValidateParameter 'serviceName' $serviceName
    
    $startModes = @("Auto","Manual","Disabled")
    if($startMode -ne $null -and $startMode -ne "" -and ($startModes -notcontains $startMode))
    {
        Throw "Parameter startMode should be empty or have one of the following enumerator names: $startModes."
    }

    if($serviceName.Contains('*') -or $serviceName.Contains('?'))
    {
        if($startMode -ne $null -and $startMode -ne "")
        {
            $services =  Get-WmiObject win32_service | Where-Object {($_.Name -like $serviceName) -and ($_.StartMode -eq $startMode) -and ($_.State -ne 'running') -and ($_.DisplayName -like $serviceDisplayName)}
            if($services -ne $null)
            {
                if($startMode -eq 'Disabled')
                {
                    $services | Set-Service -StartupType Automatic
                }
            }
        }
        else
        {
            $disabledServices = Get-WmiObject win32_service | Where-Object {($_.Name -like $serviceName) -and ($_.StartMode -eq 'Disabled') -and ($_.State -ne 'running') -and ($_.DisplayName -like $serviceDisplayName)}
            if($disabledServices -ne $null)
            {
                $disabledServices | Set-Service -StartupType Automatic
            }
            $services = Get-WmiObject win32_service | Where-Object {($_.Name -like $serviceName) -and ($_.State -ne 'running') -and ($_.DisplayName -like $serviceDisplayName)}
        }
    }
    else
    {
        $disabledServices = Get-WmiObject win32_service | Where-Object {($_.Name -eq $serviceName) -and ($_.StartMode -eq 'Disabled') -and ($_.State -ne 'running')}
        if($disabledServices -ne $null)
        {
            $disabledServices | Set-Service -StartupType Automatic
        }
        $services = Get-WmiObject win32_service | Where-Object {($_.Name -eq $serviceName) -and ($_.State -ne 'running')}
    }
    if($services -ne $null)
    {
        $services | Start-Service
    }
}

#-----------------------------------------------------------------------------------
# <summary>
# Get the first same substring of the two strings.
# </summary>
# <param name="string1">The first string</param>
# <param name="string2">The second string</param>
# <returns>Return the first same substring of the two strings.</returns>
#-----------------------------------------------------------------------------------
function GetFirstSameSubstring
{
    param(
    [string]$string1,
    [string]$string2
    )

    #----------------------------------------------------------------------------
    # Parameter validation
    #----------------------------------------------------------------------------
    ValidateParameter 'string1' $string1
    ValidateParameter 'string2' $string2

    for ($i = 0; $i -lt $string1.Length; $i++)
    {
        for ($j = 1; $j -le ($string1.Length-$i); $j++)
        {
            if(!($string2.Contains($string1.Substring($i, $j))))
            {
                break
            }
        }
        if($j -eq 1)
        {
            continue
        }
        else
        {
            return $string1.Substring($i,$j-1)
        }
    }      
    return ""
}
#-------------------------------------------------------------------------------------------
# <summary>
# Check whether the specified Distribution Group exists or not.
# </summary>
# <param name="distributionGroupName">The name of the Distribution Group that will be checked.</param>
# <returns>
# Return true if the Distribution Group already exists.
# Return false if the Distribution Group does not exist.
# </returns>
#-------------------------------------------------------------------------------------------- 
function CheckDistributionGroup
{
    param(
    [String]$distributionGroupName
    ) 
	
    $distributionGroupInfo = Get-DistributionGroup | where {$_.Name -eq $distributionGroupName}
    if(($distributionGroupInfo -ne $null) -and ($distributionGroupInfo -ne ""))
    {    
        return $true        
    }
    else
    {
        return $false
    }
}
#-------------------------------------------------------------------------------------------
# <summary>
# Create a distributionGroup.
# </summary>
# <param name="distributionGroupName">The name of the Distribution Group that will be created.</param>
# <param name="groupDomain">The name of the domain that the group belongs to.</param>
#-------------------------------------------------------------------------------------------- 
function NewDistributionGroup
{
    param(
    [string]$distributionGroupName,
    [string]$groupDomain
    )
	
    #------------------------------------------------------
    # Parameter validation
    #------------------------------------------------------
    if(($distributionGroupName -eq $null) -or ($distributionGroupName -eq ""))
    {
    	Throw "Parameter distributionGroupName cannot be empty."
    }
    if(($groupDomain -eq $null) -or ($groupDomain -eq ""))
    {
    	Throw "Parameter groupDomain cannot be empty."
    }
	
    $exist = CheckDistributionGroup $distributionGroupName
	
    if($exist -eq $true)
    {
        Output "Distribution Group $distributionGroupName already exists." "Yellow"
    }
    else
    {
        New-DistributionGroup -Name $distributionGroupName -Type 'Distribution' -OrganizationalUnit "$groupDomain/Users" -SamAccountName $distributionGroupName -Alias $distributionGroupName |Out-File -FilePath $logFile -Append -encoding ASCII -width 100
        $check = CheckDistributionGroup $distributionGroupName
        if($check)
        {
            Output "Distribution Group $distributionGroupName is created successfully." "Green"
        }
        else
        {
            throw "Failed to create Distribution Group $distributionGroupName."
        }
    }
}

#-------------------------------------------------------------------------------------------
# <summary>
# Check whether the user is a member of the distributionGroup.
# </summary>
# <param name="distributionGroup">The name of the distributionGroup to be checked whether containing the specified user.</param>
# <param name="groupMember">The name of the user to be checked.</param>
# <returns>
# Return true if the user is already a member of the distributionGroup.
# Return false if the user is not a member of the distributionGroup.
# </returns>
#-------------------------------------------------------------------------------------------- 
function CheckDistributionGroupMember
{
    param(
    [string]$distributionGroup,
    [string]$groupMember
    )
	
    $groupMembers= Get-DistributionGroupMember -Identity $distributionGroup
    if(($groupMembers -ne $null)-and ($groupMembers -ne ""))
    {
        foreach($member in $groupMembers )
        {
            if($member.name -eq $groupMember)
            {
                return $true
            }
        }
    }
    return $false
}
	
#---------------------------------------------------------------------------------------------------------
# <summary>
# Add a user into the specified distributionGroup.
# </summary>
# <param name="distributionGroup">The name of the distributionGroup that the user will be added to.</param>
# <param name="groupMember">The name of the user to be added to the group.</param>
#--------------------------------------------------------------------------------------------------------- 
function AddDistributionGroupMember
{
    param(
    [string]$distributionGroup,
    [string]$groupMember
    )
	
    #------------------------------------------------------
    # Parameter validation
    #------------------------------------------------------
    if(($distributionGroup -eq $null) -or ($distributionGroup -eq ""))
    {
    	Throw "Parameter distributionGroup cannot be empty."
    }
    if(($groupMember -eq $null) -or ($groupMember -eq ""))
    {
    	Throw "Parameter groupMember cannot be empty."
    }
	
    $exist = CheckDistributionGroupMember $distributionGroup $groupMember
		
    if($exist -eq $true)
    {
        Output "The user $groupMember is already a member of the group $distributionGroup" "Yellow"
    }
    else
    {
        Add-DistributionGroupMember  -Identity $distributionGroup -Member $groupMember 
        $check = CheckDistributionGroupMember $distributionGroup $groupMember
	    if($check)
        {
           Output "$groupMember was added to the group $distributionGroup successfully." "Green"
        }
        else
        {
            throw "Failed to add the user $groupMember to the group $distributionGroup."
        }
        
    }
}
