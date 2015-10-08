 [reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null
 [reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null

function Show-TreeSize{
    param ([xml]$XML)
          
    function DisplayDir_wander($XMLElement, $TreeNode){
		foreach($element in $XMLElement.get_ChildNodes()){ #|sort-object name){
		    if ($element.get_Name() -eq "folder"){
                $SubTreeNode = new-object System.Windows.Forms.TreeNode
			    $SubTreeNode.Text = "$($element.name) - [$([math]::truncate($element.size / 1MB))]"
                $SubTreeNode.Tag = $element
                $SubTreeNode.ImageIndex = 0
			    [Void]$TreeNode.Nodes.Add($SubTreeNode)			
				DisplayDir_wander ($element) ($SubTreeNode)
			}
		}
	}
    #create the Windows Form
    $form = new-object System.Windows.Forms.Form    
	$form.Size = new-object System.Drawing.Size(600,310)    
	$form.text = "Ormer TreeSize"
    $form.AutoSize = $true
    $form.WindowState = [System.Windows.Forms.FormWindowState]::Maximized
    
    #create the ImageList for the file and folder icons
    $imageList = [System.Windows.Forms.ImageList]::new() 
    $imageList.Images.Add("folder", [System.Drawing.Image]::FromFile("C:\Users\cdekk\Documents\GitHub\Ontwikkeling\Windows\Generic\Folder.ico"))
    $imageList.Images.Add("file", [System.Drawing.Image]::FromFile("C:\Users\cdekk\Documents\GitHub\Ontwikkeling\Windows\Generic\File.ico"))
    $imageList.ImageSize = [System.Drawing.Size]::new(16,16)   
    
    #create the TreeView control
    $treeview = new-object windows.forms.TreeView
    $treeview.size = new-object System.Drawing.Size(400,269)   
	$treeview.Anchor = "top, left, bottom"
    $treeview.AutoSize = $true
    $treeview.ImageList = $imageList

    #add the TreeView control to the Windows Form  
    $form.Controls.Add($treeview)
        
    #select the root-node of the XML file    
    $XMLRoot = $XML.selectSingleNode("/*")
    
    #create the TreeNode Control and set the Text for the root of the control
	$TreeNode = new-object Windows.Forms.TreeNode 
	$TreeNode.Text = $XMLRoot.get_Name()
    $TreeNode.Tag = $XMLRoot
    #set the TreeNode Control to expand on loading
    $TreeNode.Expand()
        
	#recursively iterate through the XML-file			
	DisplayDir_wander ($XMLRoot) ($TreeNode)
	
    #add the generated TreeNodes to the TreeView Control	
	[void]$treeview.Nodes.Add($TreeNode)
    
    #Create the ListView Control and set it's properties
    $listview = New-Object Windows.Forms.ListView    
	$listview.Location = New-Object System.Drawing.Size(405, 0)
	$listview.Size = New-Object System.Drawing.Size(295,269)
	$listview.Anchor = "top, left, bottom, right"	
	$listview.View = [Windows.Forms.View]::Details
	$listview.AllowColumnReorder = $true
    $listview.AutoResizeColumns([Windows.Forms.ColumnHeaderAutoResizeStyle]::HeaderSize)
    $listview.SmallImageList = $imageList

    #add the ListView Control to the Form
    $form.Controls.Add($listview)

    # add columns
    [void]$listview.Columns.Add("Name", -2, [Windows.forms.HorizontalAlignment]::left)
	foreach($att in $XML.SelectSingleNode("//file").SelectNodes("@*[not(name()='name')]"))
    {
        #get column name and capitalize first letter
        $columnName = ($att.get_Name()).Substring(0,1).ToUpper() + ($att.get_Name()).Substring(1).ToLower()
        if($columnName -eq "Size")
        {
            $columnName = $columnName + " (MB)"
        }      
        [void]$listview.Columns.Add($columnName, -2, [Windows.Forms.HorizontalAlignment]::Right)
    }
    $treeview.add_AfterSelect({
        $listview.Items.Clear()
        $xmlnode = $treeview.SelectedNode.Tag
        foreach($child in $xmlnode.get_ChildNodes())
        {            
            $item = new-object windows.forms.ListViewItem($child.Name)
            if($child.LocalName -eq "folder")
            {
                $item.ImageIndex = 0
            }
            else
            {
                $item.ImageIndex = 1
            }            
            
            foreach($column in ($listview.Columns|where{$_.Text -ne "Name"}))
            {                                 
                if($child.($column.Text) -ne $null)
                {
                    $item.SubItems.Add($child.($column.Text))                                   
                }

                if($column.Text -eq "Size (MB)")
                {   
                    #$item.SubItems.Add($child.size)                     
                    $item.SubItems.Add($([math]::truncate($child.size / 1MB)).ToString())
                }
            }
            $listview.Items.Add($item)
        }
    })
    #cleanup memory by clearing the XML-file variable
    Clear-Variable file -Force
    
    #display the Form
    [void]$form.showdialog()
    $form.Dispose()
}

#Get-DirAsXml -indir "C:\Users\cdekk\Desktop" -outfile "C:\Users\cdekk\Desktop\contents.xml" -props @{Length=""}
[xml]$file = Get-Content -Path C:\Users\cdekk\Desktop\F-.xml
Show-TreeSize -XML $file