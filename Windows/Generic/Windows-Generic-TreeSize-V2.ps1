[cmdletbinding()]
param (
    [parameter(mandatory=$true)]
    #[ValidateScript({Test-Path $_})]
    [string]$PathsToProcess,

    [parameter(mandatory=$true)]
    [ValidateScript({Test-Path $_})]
    [string]$TreeSizeOutputDir
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
        Write-Host "Searching for the first parent folder that is less than 248 characters..."
        $substDriveLetter = Get-ChildItem function:[d-z]: -n | Where-Object { !(test-path $_) } | Select-Object -First 1
        $parentFolder = ($currentDirInfo.Substring(0,$currentDirInfo.LastIndexOf("\")))
        $relative = $currentDirInfo.Substring($currentDirInfo.LastIndexOf("\"))
        while ($parentFolder.Length -gt 248)
        {            
            $relative = ($parentFolder.Substring($parentFolder.LastIndexOf("\")))+$relative
            $parentFolder = ($parentFolder.Substring(0,$parentFolder.LastIndexOf("\")))           
        }
        $relative = $substDriveLetter+($relative)
        
        Write-Host "Mapping $substDriveLetter to $parentFolder for access via $relative"
        subst $substDriveLetter $parentFolder

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
    $DirectoryTreeObject.Type = "Folder";
    
    # iterate all subdirectories
    try
    {
        #to do: add check if subst command completed succesfully
        $dirs = $dirInfo.GetDirectories() | where {!$_.Attributes.ToString().Contains("ReparsePoint")}; #don't include reparse points
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
            Get-DirectoryTree -DirectoryTreeObject $subFolder -CurrentDirInfo ($currentDirInfo + "\" + $_.Name)            
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
                'SizeBytes' = $_.Length
            }
            # add the file's size to the running total for the current folder
            $DirectoryTreeObject.SizeBytes= $DirectoryTreeObject.SizeBytes + $_.Length
        }
    }
    catch [Exception]
    {
        if ($_.Exception.Message.StartsWith('Access to the path'))
        {
            $DirectoryTreeObject.Name = $DirectoryTreeObject.Name + " (Access Denied to this location)"
        }
        else
        {
            Write-Host $_.Exception.ToString()
        }
    }
} 

function outputNode_Recursive{
    param (
        [Parameter(Mandatory=$true)][Object] $node
    )

    if ($node.Folders.Length -gt 1)
    {
        $folders = $node.Folders | Sort -Descending {$_.SizeBytes}
    }
    else
    {
        $folders = $node.Folders
    }    

    # iterate each subfolder
    for ($i = 0; $i -lt $node.Folders.Length; $i++)
    {
        $_ = $folders[$i];
        # append to the string buffer a HTML List Item which represents the properties of this folder
        
        $name = $_.Name.replace("'","\'")
        Write-Host "Folder: $($name) ($($_.SizeBytes))"
        
        if ($name -eq "winsxs")
        {
            sbAppend "<li><span class='folder'>Contents of folder hidden as <a href='http://support.microsoft.com/kb/2592038'>winsxs</a> commonly contains tens of thousands of files</span></li>"
        }
        elseif ($folderSizeFilterDepthThreshold -le $CurrentDepth -and $_.SizeBytes -lt $folderSizeFilterMinSize)
        {
            sbAppend "<li><span class='folder'>Contents of folder hidden via size filter</span></li>"
        }
        else
        {
            # call this function in the subfolder. It will return after the entire branch from here down is output to the string buffer
            outputNode_Recursive $_ $sb $topFilesCountPerFolder $folderSizeFilterDepthThreshold $folderSizeFilterMinSize ($CurrentDepth+1);
        }
        
        sbAppend "</ul>
    </li>"
        
    } 
    # If there is more than one file on level, sort by size, largest first
    if ($node.Files.Length -gt 1)
    {
        $files = $node.Files | Sort-Object -Descending {$_.SizeBytes}
    }
    else
    {
        $files = $node.Files
    }
    # iterate each file
    for ($i = 0; $i -lt $node.Files.Length; $i++)
    {
        if ($i -lt $topFilesCountPerFolder)
        {
            $_ = $files[$i];
            # append to the string buffer a HTML List Item which represents the properties of this file
            $size = bytesFormatter $_.SizeBytes $displayUnits
            $name = $_.Name.replace("'","\'")
            sbAppend "<li><span class='file'>$name ($size)</span></li>"
        }
        else
        {
            $remainingFilesSize = 0;
            while ($i -lt $node.Files.Length)
            {
                $remainingFilesSize += $files[$i].SizeBytes
                $i++;
            }
            $size = bytesFormatter $_.SizeBytes $displayUnits
            $name = "..."+($node.Files.Length-$topFilesCountPerFolder)+" more files"
            sbAppend "<li><span class='file'>$name ($size)</span></li>"
        }
    }
}

function Format-DirectoryTreeAsXML($OutputFile, $DirectoryTree, $XMLRoot)
{
    [xml]$xml = New-Object -TypeName System.Xml.XmlDocument
    $XMLRoot = $XMLRoot.Replace("\","-").Replace(":","")
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
                $nel = $xml.CreateElement("file")
                $nelfile = $XMLElement.AppendChild($nel)
                $nel.SetAttribute("name", $files[$i].Name)
                $nel.SetAttribute("size", $files[$i].SizeBytes)
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
             
            for ($i = 0; $i -lt $DirectoryTree.Folders.Count; $i++)
            {             
                $nel = $xml.CreateElement("folder")
                $neldir = $XMLElement.appendChild($nel)
                $nel.SetAttribute("name", $folders[$i].Name)
                $nel.SetAttribute("size", $folders[$i].SizeBytes)
                Save-XMLDirectoryStructure -XMLElement $neldir -DirectoryTree $folders[$i]            
            }
        }
    }
    Save-XMLDirectoryStructure -XMLElement $xmlRootElement -DirectoryTree $DirectoryTree
    $xml.Save($OutputFile)    
}

# passing in "ALL" means that all fixed disks are to be included in the report
if ($PathsToProcess -eq "All")
{
    $logicalDisks = Get-WmiObject WIN32_LogicalDisk -Filter "DriveType = 3"
    foreach ($logicalDisk in $logicalDisks)
    {
        $pathsArray += @($logicalDisk.DeviceID+"\")
        $xmlFilenamesArray += @($logicalDisk.DeviceID.replace(":","_Drive"))           
    }  
}
else
{
    $pathsArray = $PathsToProcess.split(",")    
    foreach($path in $pathsArray)
    {
        $xmlFilenamesArray += ,$path.Replace("\","-").Replace(":","")
    }    
}
$xmlFilenamesArray
$pathsArray

for ($i = 0; $i -lt $pathsArray.Count; $i++)
{ 
    #Generate the directory tree object
    $directoryTree = @{}    
    Get-DirectoryTree -DirectoryTreeObject $directoryTree -CurrentDirInfo $pathsArray[$i]

    #Convert the directory tree object to an XML-file
    Format-DirectoryTreeAsXML -OutputFile "$($TreeSizeOutputDir)\$($xmlFilenamesArray[$i]).xml" -DirectoryTree $directoryTree -XMLRoot "$($xmlFilenamesArray[$i])"   
}