[cmdletbinding()]
param (
    [parameter(mandatory=$true)]
    [ValidateNotNullorEmpty()]
    [ValidateScript(
    {
        if($_ -eq 'All')
        {
            Return $true
        }
        else        
        {
            $paths = $_.Split(',')
            if($paths.Count -gt 1)        
            {
               foreach ($path in $paths)
               {
                   if(!(Test-Path $path) -eq $true)
                   {
                      Throw "[$($_)] contains a path that doesn't exist"
                   }
                   else
                   {
                        Return $true
                   }
               }
            }
            else
            {
                if(Test-Path $_)
                {
                    Return $true
                }
                else
                {
                   Throw "[$($_)] contains a path that doesn't exist or is incorrectly formatted" 
                }
            }
        }
    }
    )]
    [string]$PathsToProcess,

    [parameter(mandatory=$true)]
    [ValidateScript({Test-Path $_})]
    [string]$TreeSizeOutputDir,

    [parameter(mandatory=$false)]    
    [int]$NumberOfFilesToIncludePerFolder = -1,
 
    [parameter(mandatory=$false)]    
    [int]$FolderSizeThresholdInBytes = -1,
 
    [parameter(mandatory=$false)]    
    [int]$FolderDepthThreshold = -1,

    [parameter(mandatory=$false)]    
    [switch]$NoOutPutFilter
)

function Get-DirectoryTree {  
    param (  
        [Parameter(Mandatory=$true)][Object] $DirectoryTreeObject,  
        [Parameter(Mandatory=$true)][String] $CurrentDirInfo 
    )
    $substDriveLetter = $null
    
    # if the current directory length is too long, try to work around the feeble Windows size limit by using the subst command
    if ($currentDirInfo.Length -gt 248)
    {
        Write-Host "$currentDirInfo has a length of $($currentDirInfo.Length), greater than the maximum 248, invoking workaround"
        Write-Host 'Searching for the first parent folder that is less than 248 characters...'
        $substDriveLetter = Get-ChildItem function:[d-z]: -Name | Where-Object { !(Test-Path $_) } | Select-Object -First 1
        $parentFolder = ($currentDirInfo.Substring(0,$currentDirInfo.LastIndexOf('\')))
        $relative = $currentDirInfo.Substring($currentDirInfo.LastIndexOf('\'))
        #account for cases where even the lenght of the parent folder of the parent folder exceeds the 248-character limit
        while ($parentFolder.Length -gt 248)
        {            
            $relative = ($parentFolder.Substring($parentFolder.LastIndexOf('\')))+$relative
            $parentFolder = ($parentFolder.Substring(0,$parentFolder.LastIndexOf('\')))           
        }
        $relative = $substDriveLetter+($relative)
        
        Write-Host "Mapping $substDriveLetter to $parentFolder for access via $relative"
        subst $substDriveLetter $parentFolder
        #to do: add check if subst command completed succesfully

        $dirInfo = New-Object System.IO.DirectoryInfo $relative
    }
    else
    {
        $dirInfo = New-Object System.IO.DirectoryInfo $currentDirInfo
    }

    # add its details to the currentParentDirInfo object
    $DirectoryTreeObject.Files = @()
    $DirectoryTreeObject.Folders = @()
    $DirectoryTreeObject.SizeBytes = 0;
    $DirectoryTreeObject.Name = $dirInfo.Name;
    $DirectoryTreeObject.Type = 'Folder';
    
    # iterate all subdirectories
    try
    {        
        $dirs = $dirInfo.GetDirectories() | where {!$_.Attributes.ToString().Contains('ReparsePoint')}; #don't include reparse points
        $files = $dirInfo.GetFiles();
        # remove any drive mappings created via subst above
        if (!($substDriveLetter -eq $null))
        {
            Write-Host "removing substitute drive $substDriveLetter"
            subst $substDriveLetter /D
            $substDriveLetter = $null
        }

        $dirs | foreach { 
            # create a new object for the subfolder to pass in
            $subFolder = @{}
            if ($_.Name.length -lt 1)
            {
                return;
            }
            # call this function in the subfolder. It will return after the entire branch from here down is traversed
            Get-DirectoryTree -DirectoryTreeObject $subFolder -CurrentDirInfo ($currentDirInfo + '\' + $_.Name)            
            # add the subfolder object to the list of folders at this level
            $DirectoryTreeObject.Folders += $subFolder
            # the total size consumed from the subfolder down is now available. 
            # Add it to the running total for the current folder
            $DirectoryTreeObject.SizeBytes= $DirectoryTreeObject.SizeBytes + $subFolder.SizeBytes
        }
        # iterate all files
        $files | foreach { 
            # add the file object to the list of files at this level
            $DirectoryTreeObject.Files += @{
                'Type' = 'File'
                'Name' = $_.Name
                'Extension' = $_.Extension
                'SizeBytes' = $_.Length
                'Modified' = $_.LastWriteTime
                'Created' = $_.CreationTime
            }
            # add the file's size to the running total for the current folder
            $DirectoryTreeObject.SizeBytes= $DirectoryTreeObject.SizeBytes + $_.Length
        }
    }
    catch [Exception]
    {
        if ($_.Exception.Message.StartsWith('Access to the path'))
        {
            $DirectoryTreeObject.Name = $DirectoryTreeObject.Name + ' (Access Denied to this location)'
        }
        else
        {
            Write-Host $_.Exception.ToString()
        }
    }
} 

function Format-DirectoryTreeAsXML
{
    param (
        [parameter(mandatory=$true)]
        [string]$OutputFile,

        [parameter(mandatory=$true)]
        [hashtable]$DirectoryTree,

        [parameter(mandatory=$true)]
        [string]$XMLRoot,

        [parameter(mandatory=$false)]
        [int]$NumberOfFilesToIncludePerFolder = -1,

        [parameter(mandatory=$false)]
        [int]$FolderSizeThresholdInBytes = -1,

        [parameter(mandatory=$false)]
        [int]$FolderDepthThreshold = -1,

        [parameter(mandatory=$false)]
        [int]$CurrentFolderDepth = 0
    )    

    [xml]$xml = New-Object -TypeName System.Xml.XmlDocument
    $XMLRoot = $XMLRoot.Replace('\','-').Replace(':','')
    $xml.AppendChild($xml.CreateXmlDeclaration('1.0', 'utf-8', $null)) | Out-Null
    $xml.AppendChild( ($xmlRootElement = $xml.CreateElement($XMLRoot))) | Out-Null

    function Save-XMLDirectoryStructure($XMLElement, $DirectoryTree)
    {
        if($DirectoryTree.Files.Count -gt 0)
        {
            if ($DirectoryTree.Files.Count -gt 1)
            {
                $files = $DirectoryTree.Files | Sort-Object -Descending {$_.SizeBytes}
            }
            else
            {
                $files = $DirectoryTree.Files
            }
        
            for ($i = 0; $i -lt $DirectoryTree.Files.Count; $i++)
            {
                #Only include the number of files specified in the $NumberOfFilesToIncludePerFolder variable.
                #If the $NumberOfFilesToIncludePerFolder variable is set to -1, include all files.
                if($i -lt $NumberOfFilesToIncludePerFolder -or $NumberOfFilesToIncludePerFolder -eq -1)
                {
                    $nel = $xml.CreateElement('file')
                    $nelfile = $XMLElement.AppendChild($nel)
                    $nel.SetAttribute('name', $files[$i].Name)
                    $nel.SetAttribute('size', $files[$i].SizeBytes)
                    $nel.SetAttribute('extension', $files[$i].Extension)
                    $nel.SetAttribute('modified', $files[$i].Modified)
                    $nel.SetAttribute('created', $files[$i].Created)
                }

                if($i -eq $NumberOfFilesToIncludePerFolder)
                {
                    $nel = $xml.CreateElement('file')
                    $nelfile = $XMLElement.AppendChild($nel)
                    $nel.SetAttribute('name', 'Additional files hidden by file count filter')
                    $nel.SetAttribute('size', 0)
                }
            }
        }

        if($DirectoryTree.Folders.Count -gt 0)
        {
            if($DirectoryTree.Folders.Count -gt 1)
            {
                $folders = $DirectoryTree.Folders | Sort-Object -Descending {$_.SizeBytes}
            }
            else
            {
                $folders = $DirectoryTree.Folders 
            }

            #Increment the $CurrentFolderDepth variable to keep track the current folder depth
            $CurrentFolderDepth++ 
            for ($i = 0; $i -lt $DirectoryTree.Folders.Count; $i++)
            {                
                if($CurrentFolderDepth -eq $FolderDepthThreshold)
                {
                    $nel = $xml.CreateElement('folder')
                    $neldir = $XMLElement.appendChild($nel)
                    $nel.SetAttribute('name', $folders[$i].Name)
                    $nel.SetAttribute('size', $folders[$i].SizeBytes)
                    $nel = $xml.CreateElement('file')
                    $nelfile = $neldir.AppendChild($nel)
                    $nel.SetAttribute('name', '(Folder content hidden by folder depth threshold)')
                    $nel.SetAttribute('size', 0)                   
                }
                #Hide the contents of the winsxs folder, as it contains files that are hardlinked in other locations in the filesystem.
                #Additionaly, the winsxs folder cannot be cleaned, so reporting files and their sizes makes no sense.                
                elseif($folders[$i].Name -eq 'winsxs')
                {
                    $nel = $xml.CreateElement('folder')
                    $neldir = $XMLElement.appendChild($nel)
                    $nel.SetAttribute('name', $folders[$i].Name)
                    $nel.SetAttribute('size', $folders[$i].SizeBytes)
                    $nel = $xml.CreateElement('file')
                    $nelfile = $neldir.AppendChild($nel)
                    $nel.SetAttribute('name', "(Contents of folder hidden as [$($folders[$i].Name)] commonly contains tens of thousands of files)")
                    $nel.SetAttribute('size', 0)
                }
                #Only include the folders who's size exceeds the $FolderSizeThresholdInBytes variable.
                #If the $FolderSizeThresholdInBytes variable is set to -1, include all folders.
                elseif($folders[$i].SizeBytes -gt $FolderSizeThresholdInBytes)
                {             
                    $nel = $xml.CreateElement('folder')
                    $neldir = $XMLElement.appendChild($nel)
                    $nel.SetAttribute('name', $folders[$i].Name)
                    $nel.SetAttribute('size', $folders[$i].SizeBytes)

                    #Recursively call the current function until the directory tree is traversed to the final folder depth, or until the folder depth threshold is reached
                    Save-XMLDirectoryStructure -XMLElement $neldir -DirectoryTree $folders[$i]
                }
                #Hide the content of folders who's size is below the $FolderSizeThresholdInBytes variable.                
                else
                {
                    $nel = $xml.CreateElement('folder')
                    $neldir = $XMLElement.appendChild($nel)
                    $nel.SetAttribute('name', $folders[$i].Name)
                    $nel.SetAttribute('size', $folders[$i].SizeBytes)
                    $nel = $xml.CreateElement('file')
                    $nelfile = $neldir.AppendChild($nel)
                    $nel.SetAttribute('name', '(Folder content hidden by folder size filter)')
                    $nel.SetAttribute('size', 0)
                }      
            }
        }
    }
    Save-XMLDirectoryStructure -XMLElement $xmlRootElement -DirectoryTree $DirectoryTree
    $xml.Save($OutputFile)    
}

# passing in "ALL" means that all fixed disks are to be included in the report
if ($PathsToProcess -eq 'All')
{
    $logicalDisks = Get-WmiObject WIN32_LogicalDisk -Filter 'DriveType = 3'
    foreach ($logicalDisk in $logicalDisks)
    {
        $pathsArray += @($logicalDisk.DeviceID+'\')
        $xmlFilenamesArray += @($logicalDisk.DeviceID.replace(':','_Drive'))           
    }  
}
else
{
    $pathsArray = $PathsToProcess.split(',')    
    foreach($path in $pathsArray)
    {
        $xmlFilenamesArray += ,$path.Replace('\','-').Replace(':','')
    }    
}
$xmlFilenamesArray
$pathsArray

for ($i = 0; $i -lt $pathsArray.Count; $i++)
{ 
    #Generate the directory tree object
    $directoryTree = @{}    
    Get-DirectoryTree -DirectoryTreeObject $directoryTree -CurrentDirInfo $pathsArray[$i]

    #Convert the directory tree object to an XML-file, based on the specified filters. If the -NoOutputFilter switch is specified, ignore filters that might be specified and use the default values
    if($NoOutputFilter)
    {
        Format-DirectoryTreeAsXML -OutputFile "$($TreeSizeOutputDir)\$($xmlFilenamesArray[$i]).xml" -DirectoryTree $directoryTree -XMLRoot "$($xmlFilenamesArray[$i])"
    }
    else
    {
        Format-DirectoryTreeAsXML -OutputFile "$($TreeSizeOutputDir)\$($xmlFilenamesArray[$i]).xml" -DirectoryTree $directoryTree -XMLRoot "$($xmlFilenamesArray[$i])" -NumberOfFilesToIncludePerFolder $NumberOfFilesToIncludePerFolder -FolderSizeThresholdInBytes $FolderSizeThresholdInBytes -FolderDepthThreshold $FolderDepthThreshold
    }
}