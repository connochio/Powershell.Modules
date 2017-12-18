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

This script was originally created and intented to be used to allow easy asset tracking using an SCCM configuration item.

I plan to update the module in the future so that you can get asset information on multiple service tags from other machines, and optionally select if you want the registry branded with the information.


### This is originally based on code from reddit user Kreloc.
