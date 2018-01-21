package com.coursevector.chimera.plugins {
	
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	public class CRXPlugin extends Plugin {
		
		protected var _data:Object;
		protected var ba:ByteArray = new ByteArray();
		
		public function CRXPlugin() {
			super();
		}
		
		override public function parse(ba:ByteArray):void {
			_data = { };
			this.ba = ba;
			readHeader();
		}
		
		protected function readHeader():void {
			var pubLen:int;
			var sigLen:int;
			var e:PluginEvent = new PluginEvent(PluginEvent.START_GROUP, ba.position, 'Header');
			dispatchEvent(e);
			ba.endian = Endian.LITTLE_ENDIAN;
			
			// Magic Number
			e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Magic Number', ba.readUTFBytes(4), 0x00FF00);
			dispatchPluginEvent(e, ba.position);
			
			// CRX Version
			e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Version', ba.readUnsignedInt(), 0x00FF00);
			dispatchPluginEvent(e, ba.position);
			
			// Public Key Length
			e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Public Key Length', null, 0x00FF00);
			pubLen = ba.readUnsignedInt();
			e.value = pubLen;
			dispatchPluginEvent(e, ba.position);
			
			// Signature Length
			e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Signature Length', null, 0x00FF00);
			sigLen = ba.readUnsignedInt();
			e.value = sigLen;
			dispatchPluginEvent(e, ba.position);
			
			// Public Key
			e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Public Key', ba.readUTFBytes(pubLen), 0x00FF00);
			dispatchPluginEvent(e, ba.position);
			
			// Signature
			e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Signature', ba.readUTFBytes(sigLen), 0x00FF00);
			dispatchPluginEvent(e, ba.position);
			
			e = new PluginEvent(PluginEvent.END_GROUP, ba.position);
			dispatchEvent(e);
			
			readBody();
			
			ba.endian = Endian.BIG_ENDIAN;
		}
		
		protected function readBody():void {
			var e:PluginEvent = new PluginEvent(PluginEvent.START_GROUP, ba.position, 'Zip File');
			dispatchEvent(e);
			
			// Zip File
			e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Zip Contents', ba.readUTFBytes(ba.bytesAvailable), 0x00FFF0);
			dispatchPluginEvent(e, ba.position);
			
			e = new PluginEvent(PluginEvent.END_GROUP, ba.position);
			dispatchEvent(e);
		}
	}
}