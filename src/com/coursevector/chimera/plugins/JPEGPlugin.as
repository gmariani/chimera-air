package com.coursevector.chimera.plugins {
	
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	public class JPEGPlugin extends Plugin {
		
		protected var _data:Object;
		protected var ba:ByteArray = new ByteArray();
		
		public function JPEGPlugin() {
			super();
		}
		
		override public function parse(ba:ByteArray):void {
			_data = { };
			this.ba = ba;
			
			if (ba.readUnsignedShort() != 0xFFD8) {
				throw new Error("Not a valid JPEG");
				return;
			}
			
			ba.position = 0;
			
			var e:PluginEvent;
			var i:uint;
			var isStartStream:Boolean;
			var startStream:uint = 0;
			while (ba.bytesAvailable) {
				if (!isStartStream) {
					e = new PluginEvent(PluginEvent.START_GROUP, ba.position, 'Tag');
					dispatchEvent(e);
				}
				
				e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, '', null, 0x00FF00, 100);
				var marker:uint = ba.readUnsignedShort();
				e.value = marker;
				
				switch(marker) {
					case 0xFFC0 :
						e.name = '(SOF0) Start of Frame 0 - Baseline DCT';
						dispatchPluginEvent(e, ba.position);
						
						// Length
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Length', ba.readUnsignedShort(), 0x00FF00, 100);
						dispatchPluginEvent(e, ba.position);
						
						// Bit Depth
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Bit Depth', ba.readUnsignedByte(), 0x00FF00, 100);
						dispatchPluginEvent(e, ba.position);
						
						// Height
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Height', ba.readUnsignedShort(), 0x00FF00, 100);
						dispatchPluginEvent(e, ba.position);
						
						// Width
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Width', ba.readUnsignedShort(), 0x00FF00, 100);
						dispatchPluginEvent(e, ba.position);
						
						// Number of components
						/*
						Usually 1 = grey scaled, 3 = color YcbCr or YIQ
						4 = color CMYK
						*/
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Number of components', null, 0x00FF00, 100);
						var numComp:uint = ba.readUnsignedByte();
						e.value = numComp;
						dispatchPluginEvent(e, ba.position);
						
						// Each component
						// (component Id(1byte)(1 = Y, 2 = Cb, 3 = Cr, 4 = I, 5 = Q),
						// sampling factors (1byte) (bit 0-3 vertical., 4-7 horizontal.),
						// quantization table number (1 byte)).
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Components', null, 0x00FF00, 100);
						e.value = [];
						i = numComp;
						while (i--) {
							e.value.push('{ID:' + ba.readUnsignedByte() + ', Sampling Factors:' + ba.readUnsignedByte() + ', Quantization Table Number:' + ba.readUnsignedByte() + '} ');
						}
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFC1 :
						e.name = '(SOF1) Start of Frame 1 - Extended Sequential DCT';
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFC2 :
						e.name = '(SOF2) Start of Frame 2 - Progressive DCT';
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFC3 :
						e.name = '(SOF3) Start of Frame 3 - Lossless (sequential)';
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFC4 :
						e.name = '(DHT) Define Huffman Table';
						dispatchPluginEvent(e, ba.position);
						/*
						// Length
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Length', ba.readUnsignedShort(), 0x00FF00, 100);
						dispatchPluginEvent(e, ba.position);
						
						// HT Info
						/*
						bit 0..3 : number of HT (0..3, otherwise error)
						bit 4 : type of HT, 0 = DC table, 1 = AC table
						bit 5..7 : not used, must be 0
						/
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'HT Info', ba.readUnsignedByte(), 0x00FF00, 100);
						dispatchPluginEvent(e, ba.position);
						
						// Number of Symbols*/
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFC5 :
						e.name = '(SOF5) Start of Frame 5 - Differential sequential DCT';
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFC6 :
						e.name = '(SOF6) Start of Frame 6 - Differential progressive DCT';
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFC7 :
						e.name = '(SOF7) Start of Frame 7 - Differential lossless (sequential)';
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFC8 :
						e.name = '(JPG) JPEG Extensions';
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFC9 :
						e.name = '(SOF9) Start of Frame 9 - Extended sequential DCT, Arithmetic coding';
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFCA :
						e.name = '(SOF10) Start of Frame 10 - Progressive DCT, Arithmetic coding';
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFCB :
						e.name = '(SOF11) Start of Frame 11 - Lossless (sequential), Arithmetic coding';
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFCC :
						e.name = '(DAC) Define Arithmetic Coding';
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFCD :
						e.name = '(SOF13) Start of Frame 13 - Differential sequential DCT, Arithmetic coding';
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFCE :
						e.name = '(SOF14) Start of Frame 14 - Differential progressive DCT, Arithmetic coding';
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFCF :
						e.name = '(SOF15) Start of Frame 15 - Differential lossless (sequential), Arithmetic coding';
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFD0 :
						e.name = '(RST0) Restart Marker 0';
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFD1 :
						e.name = '(RST1) Restart Marker 1';
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFD2 :
						e.name = '(RST2) Restart Marker 2';
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFD3 :
						e.name = '(RST3) Restart Marker 3';
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFD4 :
						e.name = '(RST4) Restart Marker 4';
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFD5 :
						e.name = '(RST5) Restart Marker 5';
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFD6 :
						e.name = '(RST6) Restart Marker 6';
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFD7 :
						e.name = '(RST7) Restart Marker 7';
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFD8 :
						e.name = '(SOI) Start of Image';
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFD9 :
						if (isStartStream) {
							isStartStream = false;
							e = new PluginEvent(PluginEvent.HIGHLIGHT, startStream, 'Stream Data', null, 0x00FF00, 100);
							dispatchPluginEvent(e, ba.position - 2);
							
							e = new PluginEvent(PluginEvent.END_GROUP, ba.position - 2);
							dispatchEvent(e);
							
							// EOI
							e = new PluginEvent(PluginEvent.START_GROUP, ba.position - 2, 'Tag');
							dispatchEvent(e);
							
							e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position - 2, '', null, 0x00FF00, 100);
							e.value = marker;
						}
						
						e.name = '(EOI) End of Image';
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFDA :
						e.name = '(SOS) Start of Scan';
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						
						e = new PluginEvent(PluginEvent.END_GROUP, ba.position);
						dispatchEvent(e);
						
						e = new PluginEvent(PluginEvent.START_GROUP, ba.position, 'Tag');
						dispatchEvent(e);
						
						// Stream Data
						isStartStream = true;
						startStream = ba.position;
						break;
					case 0xFFDB :
						e.name = '(DQT) Define Quantization Table';
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFDC :
						e.name = '(DNL) Define Number of Lines'; // usually unsupported, ignore
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFDD :
						e.name = '(DRI) Define Restart Interval';
						dispatchPluginEvent(e, ba.position);
						
						// Length
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Length', ba.readUnsignedShort(), 0x00FF00, 100);
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFDE : // ignore
						e.name = '(DHP) Define Hierarchical Progression';
						dispatchPluginEvent(e, ba.position);
						
						// Length
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Length', ba.readUnsignedShort(), 0x00FF00, 100);
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFDF : // ignore
						e.name = '(EXP) Expand Reference Component';
						dispatchPluginEvent(e, ba.position);
						
						// Length
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Length', ba.readUnsignedShort(), 0x00FF00, 100);
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFE0 :
						e.name = '(APP0) Application Segment 0'; // JFIF/JFXX - JFIF JPEG image, AVI1 - Motion JPEG (MJPG) 
						dispatchPluginEvent(e, ba.position);
						
						// Length
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Length', ba.readUnsignedShort(), 0x00FF00, 100);
						dispatchPluginEvent(e, ba.position);
						
						// Identifier
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Identifier', null, 0x00FF00, 100);
						var id:String = ba.readUTFBytes(4);
						ba.readUnsignedByte();
						e.value = id;
						dispatchPluginEvent(e, ba.position);
						
						var tw:uint;
						var th:uint;
						if (id == 'JFIF') {
							// Version
							e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Version', null, 0x00FF00, 100);
							var maj:uint = ba.readUnsignedByte();
							var minor:uint = ba.readUnsignedByte();
							e.value = maj+'.'+minor;
							dispatchPluginEvent(e, ba.position);
							
							// Density units
							/*
							Units for pixel density fields
							
							0 - No units, aspect ratio only specified
							1 - Pixels per inch
							2 - Pixels per centimetre
							
							*/
							e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Density units', ba.readUnsignedByte(), 0x00FF00, 100);
							dispatchPluginEvent(e, ba.position);
							
							// X Density
							e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'X Density', ba.readUnsignedShort(), 0x00FF00, 100);
							dispatchPluginEvent(e, ba.position);
							
							// Y density
							e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Y density', ba.readUnsignedShort(), 0x00FF00, 100);
							dispatchPluginEvent(e, ba.position);
							
							// Thumbnail width
							e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Thumbnail width', null, 0x00FF00, 100);
							tw = ba.readUnsignedByte();
							e.value = tw;
							dispatchPluginEvent(e, ba.position);
							
							// Thumbnail height
							e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Thumbnail height', null, 0x00FF00, 100);
							th = ba.readUnsignedByte();
							e.value = tw;
							dispatchPluginEvent(e, ba.position);
							
							// Thumbnail data - 24-bit RGB
							e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Thumbnail data', null, 0x00FF00, 100);
							e.value = [];
							i = 3*tw*th;
							while (i--) {
								e.value.push(ba.readUnsignedByte());
							}
							dispatchPluginEvent(e, ba.position);
						} else if (id == 'JFXX') {
							// Thumbnail Format
							/*
							0x10 - JPEG format
							0x11 - 1 byte per pixel palettised format
							0x13 - 3 byte per pixel RGB format
							*/
							e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Thumbnail Format', null, 0x00FF00, 100);
							var format:uint = ba.readUnsignedByte();
							e.value = format;
							dispatchPluginEvent(e, ba.position);
							
							if (format == 0x11) {
								// Thumbnail width
								e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Thumbnail width', null, 0x00FF00, 100);
								tw = ba.readUnsignedByte();
								e.value = tw;
								dispatchPluginEvent(e, ba.position);
								
								// Thumbnail height
								e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Thumbnail height', null, 0x00FF00, 100);
								th = ba.readUnsignedByte();
								e.value = tw;
								dispatchPluginEvent(e, ba.position);
								
								// Thumbnail palette
								e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Thumbnail palette', null, 0x00FF00, 100);
								e.value = [];
								i = 768;
								while (i--) {
									e.value.push(ba.readUnsignedByte());
								}
								dispatchPluginEvent(e, ba.position);
								
								// Thumbnail data - Pixel data - each value gives a position within the palette
								e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Thumbnail data', null, 0x00FF00, 100);
								e.value = [];
								i = tw*th;
								while (i--) {
									e.value.push(ba.readUnsignedByte());
								}
								dispatchPluginEvent(e, ba.position);
							} else if (format == 0x13) {
								// Thumbnail width
								e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Thumbnail width', null, 0x00FF00, 100);
								tw = ba.readUnsignedByte();
								e.value = tw;
								dispatchPluginEvent(e, ba.position);
								
								// Thumbnail height
								e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Thumbnail height', null, 0x00FF00, 100);
								th = ba.readUnsignedByte();
								e.value = tw;
								dispatchPluginEvent(e, ba.position);
								
								// Thumbnail data - 24-bit RGB
								e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Thumbnail data', null, 0x00FF00, 100);
								e.value = [];
								i = 3*tw*th;
								while (i--) {
									e.value.push(ba.readUnsignedByte());
								}
								dispatchPluginEvent(e, ba.position);
							}
						}
						break;
					case 0xFFE1 :
						e.name = '(APP1) Application Segment 1'; // EXIF Metadata, TIFF IFD format, JPEG Thumbnail (160x120) Adobe XMP 
						dispatchPluginEvent(e, ba.position);
						
						// Length
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Length', null, 0x00FF00, 100);
						var length:uint = ba.readUnsignedShort();
						e.value = length;
						dispatchPluginEvent(e, ba.position);
						
						// Identifier
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Identifier', null, 0x00FF00, 100);
						id = ba.readUTFBytes(4);
						ba.readUnsignedByte();
						ba.readUnsignedByte();
						e.value = id;
						dispatchPluginEvent(e, ba.position);
						
						// Endianness
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Endianness', null, 0x00FF00, 100);
						var endian:String = ba.readUTFBytes(2);
						if (endian == 'MM') e.value = 'Big Endian';
						if (endian == 'II') e.value = 'Little Endian';
						dispatchPluginEvent(e, ba.position);
						
						// Signature
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Signature', ba.readUnsignedShort(), 0x00FF00, 100);
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += (length - 10);
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFE2 :
						e.name = '(APP2) Application Segment 2'; // ICC color profile, FlashPix
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFE3 :
						e.name = '(APP3) Application Segment 3'; // (Not common) JPS Tag for Stereoscopic JPEG images 
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFE4 :
						e.name = '(APP4) Application Segment 4';
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFE5 :
						e.name = '(APP5) Application Segment 5';
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFE6 :
						e.name = '(APP6) Application Segment 6'; // (Not common) NITF Lossles profile 
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFE7 :
						e.name = '(APP7) Application Segment 7';
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFE8 :
						e.name = '(APP8) Application Segment 8';
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFE9 :
						e.name = '(APP9) Application Segment 9';
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFEA :
						e.name = '(APP10) Application Segment 10'; // (Not common) ActiveObject (multimedia messages / captions) 
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFEB :
						e.name = '(APP11) Application Segment 11'; // (Not common) HELIOS JPEG Resources (OPI Postscript) 
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFEC :
						e.name = '(APP12) Application Segment 12'; // Picture Info (older digicams), Photoshop Save for Web: Ducky 
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFED :
						e.name = '(APP13) Application Segment 13'; // Photoshop Save As: IRB, 8BIM, IPTC 
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFEE :
						e.name = '(APP14) Application Segment 14';
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFEF :
						e.name = '(APP15) Application Segment 15';
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFF0 :
						e.name = '(JPG0) JPEG Extension 0'; // ignore
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFF1 :
						e.name = '(JPG1) JPEG Extension 1'; // ignore
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFF2 :
						e.name = '(JPG2) JPEG Extension 2'; // ignore
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFF3 :
						e.name = '(JPG3) JPEG Extension 3'; // ignore
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFF4 :
						e.name = '(JPG4) JPEG Extension 4'; // ignore
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFF5 :
						e.name = '(JPG5) JPEG Extension 5'; // ignore
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFF6 :
						e.name = '(JPG6) JPEG Extension 6'; // ignore
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFF7 :
						e.name = '(JPG7) JPEG Extension 7'; // Lossless JPEG
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFF8 :
						e.name = '(JPG8) JPEG Extension 8'; // Lossless JPEG Extension Parameters
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFF9 :
						e.name = '(JPG9) JPEG Extension 9'; // ignore
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFFA :
						e.name = '(JPG10) JPEG Extension 10'; // ignore
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFFB :
						e.name = '(JPG11) JPEG Extension 11'; // ignore
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFFC :
						e.name = '(JPG12) JPEG Extension 12'; // ignore
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFFD :
						e.name = '(JPG13) JPEG Extension 13'; // ignore
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
					case 0xFFFE :
						e.name = '(COM) Comment'; // Comment
						dispatchPluginEvent(e, ba.position);
						
						// Data
						e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Data', null, 0x00FF00, 100);
						ba.position += ba.readUnsignedShort();
						dispatchPluginEvent(e, ba.position);
						break;
				}
				
				if (!isStartStream) {
					e = new PluginEvent(PluginEvent.END_GROUP, ba.position);
					dispatchEvent(e);
				}
			}
		}
	}
}