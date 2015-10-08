# Author:		Chris Bayes
# Date:			25-Nov-2008
# Description:	C# Code to set the ImageList of a TreeView or ListView control
# Usage:
#	. .\ImageListHandle.ps1
#
#	$SHGFI_SMALLICON = 1;$SHGFI_LARGEICON = 0 
#	$LISTVIEW = new-object System.Windows.Forms.ListView
#	[void][cjb.Shell32]::SetSystemImageListHandle($LISTVIEW, $SHGFI_SMALLICON)
#	$TREEVIEW = new-object System.Windows.Forms.TreeView
#	[void][cjb.Shell32]::SetSystemImageListHandle($TREEVIEW, $SHGFI_SMALLICON)
#	
#	$tn = new-object System.Windows.Forms.TreeNode
#	$tn.ImageIndex = $tn.SelectedImageIndex = [cjb.Shell32]::GetSystemImageListIndex($e.Name, ($e.get_Name() -eq "folder"), $SHGFI_SMALLICON)
#
#	$idx = [cjb.Shell32]::GetSystemImageListIndex($n.Name, ($n.get_Name() -eq "folder"), $SHGFI_SMALLICON)
#	$item = new-object windows.forms.ListViewItem($n.Name, $idx)
#

$code = @'
using System;
using System.Runtime.InteropServices;
namespace cjb
{
	[StructLayout(LayoutKind.Sequential)]
	public struct SHFILEINFO 
	{
		public IntPtr hIcon;
		public int iIcon;
		public uint dwAttributes;
		[MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)]
		public string szDisplayName;
		[MarshalAs(UnmanagedType.ByValTStr, SizeConst = 80)]
		public string szTypeName;
	};
	
	public static class Shell32
	{
		private const UInt32 TV_FIRST = 4352;
		private const UInt32 TVSIL_NORMAL = 0;
		private const UInt32 TVM_SETIMAGELIST = TV_FIRST + 9;

		private const UInt32 LVM_FIRST = 4096;
		private const UInt32 LVSIL_NORMAL = 0;
		private const UInt32 LVSIL_SMALL = 1;
		private const UInt32 LVM_SETIMAGELIST = LVM_FIRST + 3;

		private const uint SHGFI_SYSICONINDEX = 0x4000;
		private const uint SHGFI_ICON = 0x100;
		private const uint SHGFI_LARGEICON = 0x0;
		private const uint SHGFI_SMALLICON = 0x1;
		private const uint SHGFI_USEFILEATTRIBUTES = 0x10;
		private const uint FILE_ATTRIBUTE_NORMAL = 0x0;
		private const uint FILE_ATTRIBUTE_DIRECTORY = 0x10;
		[DllImport("Shell32.dll")]
		public static extern IntPtr SHGetFileInfo(string path, uint fileAttributes, out SHFILEINFO psfi, uint fileInfo, uint flags);
		[DllImport("user32.dll")]
		private static extern UInt32 SendMessage(IntPtr hWnd, UInt32 Msg, IntPtr wParam, IntPtr lParam);

		public static int SetSystemImageListHandle(System.Windows.Forms.Control control, uint rsize)
		{
			// rsize must be 0 or 1, SHGFI_LARGEICON or SHGFI_SMALLICON
			SHFILEINFO info = new SHFILEINFO();
			uint flags = SHGFI_SYSICONINDEX | rsize | SHGFI_ICON | SHGFI_USEFILEATTRIBUTES;
			IntPtr himl = SHGetFileInfo("c:\\boot.ini"
				, FILE_ATTRIBUTE_NORMAL
				, out info
				, (uint)Marshal.SizeOf(typeof(SHFILEINFO))
				, flags);

			if ((uint)himl != 0){
				if (control.GetType() == typeof(System.Windows.Forms.TreeView)){
					SendMessage(control.Handle
						, TVM_SETIMAGELIST
						, (IntPtr)TVSIL_NORMAL
						, himl);
					Console.WriteLine("tv handle " + himl);
				}else if (control.GetType() == typeof(System.Windows.Forms.ListView)){
					SendMessage(control.Handle
						, LVM_SETIMAGELIST
						, (IntPtr)LVSIL_SMALL
						, himl);
					SendMessage(control.Handle
						, LVM_SETIMAGELIST
						, (IntPtr)LVSIL_NORMAL
						, himl);
					Console.WriteLine("lv handle " + himl);
				}
				return (int)himl;
			}
			return 0;
		}
		public static int GetSystemImageListIndex(string filespec, bool directory, uint rsize){
			// rsize must be 0 or 1, SHGFI_LARGEICON or SHGFI_SMALLICON
			SHFILEINFO info = new SHFILEINFO();
			uint flags = SHGFI_ICON | rsize | SHGFI_USEFILEATTRIBUTES;
			uint atts = (directory?FILE_ATTRIBUTE_DIRECTORY:FILE_ATTRIBUTE_NORMAL);
			
			//if (!force){
			//	flags = flags | SHGFI_USEFILEATTRIBUTES;
			//}
			IntPtr himl = SHGetFileInfo(filespec
				, atts
				, out info
				, (uint)Marshal.SizeOf(typeof(SHFILEINFO))
				, flags
	  			);

			if ((uint)himl.ToInt32() != 0){
   				//tn.ImageIndex = tn.SelectedImageIndex = info.iIcon;
				
				return info.iIcon;
			}
			return 0;

		}
	}
}
'@

#
# This next bit of code I found at 
# http://blogs.msdn.com/powershell/archive/2006/04/25/583236.aspx
# It is used to compile the above C# code.
#
#######################################################################
#  This is a general purpose routine that I put into a file called
#  LibraryCodeGen.msh and then dot-source when I need it.
#######################################################################
function Compile-Csharp ([string] $code, $FrameworkVersion="v2.0.50727", 
[Array]$References)
{
    #
    # Get an instance of the CSharp code provider
    #
    $cp = New-Object Microsoft.CSharp.CSharpCodeProvider

    #
    # Build up a compiler params object...
    $framework = Join-Path $env:windir "Microsoft.NET\Framework\$FrameWorkVersion"
    $refs = New-Object Collections.ArrayList
    $refs.AddRange( @("${framework}\System.dll",
        "${framework}\system.windows.forms.dll",
        "${framework}\System.data.dll",
        "${framework}\System.Drawing.dll",
        "${framework}\System.Xml.dll")
		)
    if ($references.Count -ge 1)
    {
        $refs.AddRange($References)
    }

    $cpar = New-Object System.CodeDom.Compiler.CompilerParameters
    $cpar.GenerateInMemory = $true
    $cpar.GenerateExecutable = $false
    $cpar.OutputAssembly = "custom"
    $cpar.ReferencedAssemblies.AddRange($refs)
    $cr = $cp.CompileAssemblyFromSource($cpar, $code)
	
    if ( $cr.Errors.Count)
    {
        $codeLines = $code.Split("`n");
        foreach ($ce in $cr.Errors)
        {
            write-host "Error: $($codeLines[$($ce.Line - 1)])"
            $ce |out-default
        }
        Throw "INVALID DATA: Errors encountered while compiling code"
    }
}



##################################################################
# So now we compile the code and use .NET object access to run it.
##################################################################

compile-CSharp $code 


