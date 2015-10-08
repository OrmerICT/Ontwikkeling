Set-Location ($MyInvocation.MyCommand.Source).Substring(0,($MyInvocation.MyCommand.Source).IndexOf($MyInvocation.MyCommand.Name))

# Author:		Chris Bayes
# Date:			25-Nov-2008
# Description:	Get an xml representation of a directory tree.
# Example:		
#				. .\Get-DirAsXml # dot source this file
#				Get-DirAsXml c:\temp
# 
function Get-DirAsXml{

	param( 	[string[]] $indir 
			,[string] $outfile
			,[string] $rootname = $indir.Replace("\","-").Replace(":","")
			,[Object] $props
	)    
	begin {
		[xml]$xml = New-Object -TypeName System.Xml.XmlDocument
		$nowt = $xml.AppendChild($xml.CreateXmlDeclaration('1.0', 'utf-8', $null))
		$nowt = $xml.AppendChild( ( $rootelement = $xml.CreateElement($rootname) ) )
		
		function Usage{
			""
            "USAGE"
            "    Get-DirAsXml -Indir <pathToDirectory>"
            ""
            "SYNOPSIS"
            "    Formats the directory tree as XML."
            ""
            "PARAMETERS"
            "    -Indir <string[]>"
            "        The directories to be processed"
            "    -Outfile <string>"
            "        Optional output file."
            "    -Rootname <string>"
            "        Optional name of the root node."
            "    -Props <object>"
            "        Optional hash table of file properties to include in the xml"
			"        attributes."
            ""
            "EXAMPLES"
            "    Get-DirAsXml c:\temp"
            "    Get-DirAsXml c:\temp xmlFile.xml"
			"    Get-DirAsXml d:\week\log, z:\arch\log, c:\today\log allSystemLogfiles.xml"
            "    gci c:\temp | where {`$_ -like '*xml*'} | Get-DirAsXml"
            "    Get-DirAsXml c:\temp -p @{CreationTime=`"yyy-MM-dd`";LastAccessTime=`"yyy-MM-dd`"}"
			"	 Get-DirAsXml hkcu:\software\microsoft"
            ""
		}

		function DirAsXml_wander($el, $dirs)
		{
			$dir = Get-Item $dirs -force | Where {$_.attributes -match "Directory"}
			$nel = $xml.CreateElement("folder")
			$neldir = $el.appendChild($nel)
			$nel.SetAttribute("name", $dir.Name)
			foreach ($p in $props.Keys){
				if ($dir.$p -ne $null){
					if ($dir.$p -is [DateTime]){
						$nel.SetAttribute($p, $dir.$p.toString($props.$p))
					}else{
						$nel.SetAttribute($p, $dir.$p)
					}
				}
			}
			$diro = Get-ChildItem $dirs -force | Where {$_.attributes -match "Directory"}
			if ($diro){
				foreach ($dir in $diro) {
					DirAsXml_wander $neldir "$dirs\$dir"
				}
			}
			$fileo = Get-ChildItem $dirs -force |where {$_.attributes -ne "Directory"}
			if ($fileo){
				foreach ($file in $fileo) {
					$nel = $xml.createElement("file")
					$nel = $neldir.appendChild($nel)
					$nel.SetAttribute("name", $file.Name)
					foreach ($p in $props.Keys){
						if ($file.$p -ne $null){
							if ($file.$p -is [DateTime]){
								$nel.SetAttribute($p, $file.$p.toString($props.$p))
							}else{
								$nel.SetAttribute($p, $file.$p)
							}
						}
					}
				}
			}
		}
	}
	process{
		if ($_ -eq $null){$a = $indir}else{$a = $_}
		if ($a -is [Array]){
			foreach($b in $a){
				DirAsXml_wander $rootelement (Resolve-Path $b)
			}
		}
		elseif ($a -is [IO.DirectoryInfo]){
			DirAsXml_wander $rootelement $a.FullName
		}
		
		elseif ($a -is [String]){
			DirAsXml_wander $rootelement (Resolve-Path $a)
		}
		else{
			Usage
			break
		}
	}
	end{
		if ($outfile){
			$xml.Save($outfile)
		}else{
			$xml.get_OuterXml()
		}
	}
}

function Form-DisplayDirExp{
    param ([xml]$XML)
    
    $SHGFI_SMALLICON = 1;$SHGFI_LARGEICON = 0 
    
    function DisplayDir_wander($el, $tnode){
		foreach($e in $el.get_ChildNodes()){ #|sort-object name){
		    if ($e.get_Name() -eq "folder"){
                $tn = new-object System.Windows.Forms.TreeNode
			    $tn.Text = $e.name
                $tn.Tag = $e
                #$idx = [cjb.Shell32]::GetSystemImageListIndex($e.Name, ($e.get_Name() -eq "folder"), $SHGFI_SMALLICON)
                #$tn.ImageIndex = $tn.SelectedImageIndex = $idx
			    [Void]$tnode.Nodes.add( $tn )
			
				DisplayDir_wander ($e) ($tn)
			}
		}
	}
    $FORM = new-object Windows.Forms.Form    
	$FORM.Size = new-object System.Drawing.Size(600,310)    
	$FORM.text = "Form-DisplayDirExplorer"
    
    $TREEVIEW = new-object windows.forms.TreeView 
    $FORM.Controls.Add($TREEVIEW)
    $TREEVIEW.size = new-object System.Drawing.Size(295,269)   
	$TREEVIEW.Anchor = "top, left, bottom"
    $ret = [cjb.Shell32]::SetSystemImageListHandle($TREEVIEW, $SHGFI_SMALLICON)
        
    $r = $XML.selectSingleNode("/*")
	$tn = new-object System.Windows.Forms.TreeNode 
	$tn.Text = $r.get_Name()
    $tn.Tag = $r
				
	DisplayDir_wander ($r) ($tn)
		
	[void]$TREEVIEW.Nodes.Add($tn)
    
    $LISTVIEW = new-object windows.forms.ListView
    $FORM.Controls.Add($LISTVIEW)
	$LISTVIEW.Location = new-object System.Drawing.Size(300, 0)
	$LISTVIEW.Size = new-object System.Drawing.Size(295,269)
	$LISTVIEW.Anchor = "top, left, bottom, right"
	#$ret = [void][cjb.Shell32]::SetSystemImageListHandle($LISTVIEW, $SHGFI_SMALLICON)
	$LISTVIEW.View = [System.Windows.Forms.View]::Details
	$LISTVIEW.AllowColumnReorder = $true
    $LISTVIEW.AutoResizeColumns([Windows.Forms.ColumnHeaderAutoResizeStyle]::HeaderSize)
    # add columns
    [void]$LISTVIEW.Columns.Add("Name", -2, [windows.forms.HorizontalAlignment]::left)
	foreach($att in $XML.SelectSingleNode("//file"
            ).SelectNodes("@*[not(name()='name')]")){
        [void]$LISTVIEW.Columns.Add($att.get_Name(), -2, [windows.forms.HorizontalAlignment]::Right)
    }
    $TREEVIEW.add_AfterSelect({
        $LISTVIEW.Items.Clear()
        $xmlnode = $TREEVIEW.SelectedNode.Tag
        foreach($child in $xmlnode.get_ChildNodes()){
            #$idx = [cjb.Shell32]::GetSystemImageListIndex($child.Name, ($child.get_Name() -eq "folder"), $SHGFI_SMALLICON)
            $item = new-object windows.forms.ListViewItem($child.Name)
            foreach($column in ($LISTVIEW.Columns|where{$_.Text -ne "Name"})){
                if ($child.($column.Text) -ne $null){
                    $item.SubItems.Add($child.($column.Text))
                }
            }
            $LISTVIEW.Items.Add($item)
        }
    })
    
    [void]$FORM.showdialog()
    $FORM.Dispose()
}

#Get-DirAsXml -indir "C:\Users\cdekk\Desktop" -outfile "C:\Users\cdekk\Desktop\contents.xml" -props @{Length=""}
[xml]$file = Get-Content -Path C:\Users\cdekk\Desktop\C-.xml
Form-DisplayDirExp -XML $file