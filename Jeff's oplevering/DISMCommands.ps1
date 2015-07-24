# DISM Commands
# Remove ServicePack installation files - After this an ServicePack can't be uninstalled!!!
dism /online /cleanup-image /spsuperseded /NoRestart /Quiet
# If an OS upgrade was performed, this removes old mountpoints from this upgrade.
dism /Cleanup-Mountpoints
# Remove old installation files from Windows updates - After this a previously installed update can't be uninstalled!
dism /online /cleanup-image /StartComponentCleanup