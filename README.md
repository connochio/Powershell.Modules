# Dell Warranty Check and Branding


Within this repository there is both a module you can use (contained within 'Get-DellWarranty') and a script fin the archived folder than you can run on a standalone basis.  

The script will query using the Dell API key and return the following information:

   * Warranty Start Date (earliest date available)  
   * Warranty End Date (latest date available)  
   * Service Tag  
   * Machine Model  
   * Original Ship Date  
   * Type of warranty  

It can then brand the above information to the registry under HKLM\HARDWARE\WARRANTY  

___

### You will need to update the API Key by running `Get-DellAssetInformation -Api`   
This will then save the API to a file in your appdata folder.  

The API can be optained by speaking to Dell Tech Direct or by finding a working public API Key.  

If you receive a new API Key, or yours has stopped working, you can amend it by running `Get-DellAssetInformation -Api` again.  

___

### Switches and Parameters.  

The function Get-DellAssetInformation by default will only grab the information from dell for the machine that the script is being run from, and will not show or brand any information.

You can change this behaviour by specifying the service tag you want to check using the -ServiceTag Parameter  
E.g. `Get-DellAssetInformation -ServiceTag "F11F111"`  
E.g. `Get-DellAssetInformation -Show -Brand`  

You can get information within the console by using `-Show`.  
The `-Show` switch is triggered by default when using `-ServiceTag`.

You can choose to brand the information retrieved in to the registry using `-Brand`.  
By default, the location for this information will be HKLM\HARDWARE\WARRANTY  
This can be changed by changing the `$registryPath` variable.  
This switch will not work unless you are in an elevated powershell window however, and it will warn you as such.

___


### This is originally based on code from a reddit user by the name of randomness_whoaaa.
