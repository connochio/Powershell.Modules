# Dell Warranty Check and Branding


Within the repository there is both a module and a script for the dell warranty check.  
You can import the module and use 'Get-DellAssetInformation' or simply run the .ps1 file.

The script will query using the Dell API key and return the following information:

   * Warranty Start Date (earliest date available)  
   * Warranty End Date (latest date available)  
   * Service Tag  
   * Machine Model  
   * Original Ship Date  
   * Type of warranty  

It will then brand the above information to the registry under HKLM\HARDWARE\WARRANTY  
You can change the directory if you wish, as the above default requires an elevated powershell session.

___

### You will need to update the API Key in the module or script, located at the top.  
`( $APIKey = "XXXXXXXXXX" )`  

This can be optained by speaking to Dell Tech Direct or by finding a working public API Key

___

### Switches and Parameters.  

The function Get-DellAssetInformation by default will only grab the information from dell for the mchine that the script is being run from, and will not show or brand any information.

You can change this behaviour by specifying the service tag you want to check using the -ServiceTag Parameter
E.g. Get-DellAssetInformation -ServiceTag "F11F111"

You can get information within the console by using the -Show switch.

You can choose to brand the information retrieved in to the registry using the -Brand switch.  
By default, the location for this information will be HKLM\HARDWARE\WARRANTY.  
This can be changed by changing the `$registryPath` variable

___


### This is originally based on code from a reddit user by the name of randomness_whoaaa.
