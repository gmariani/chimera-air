package com.coursevector.chimera.plugins {
	
	import flash.errors.EOFError;
	import flash.events.ErrorEvent;
	import flash.events.EventDispatcher;
	import flash.net.ObjectEncoding;
	import flash.system.ApplicationDomain;
	import flash.utils.ByteArray;
	import flash.utils.getDefinitionByName;
	
	public class SharedObjectPlugin extends Plugin {
		
		protected var _data:Object;
		protected var ba:ByteArray = new ByteArray();
		protected var _amfVersion:uint;
		protected var amf0:AMF0Plugin;
		protected var amf3:AMF3Plugin;
		
		public function SharedObjectPlugin() {
			super();
		}
		
		override public function parse(ba:ByteArray):void {
			_data = { };
			this.ba = ba;
			readHeader();
		}
		
		protected function readHeader():void {
			var nLenFile:uint = ba.bytesAvailable;
			
			var e:PluginEvent = new PluginEvent(PluginEvent.START_GROUP, ba.position, 'SOL Tag');
			dispatchEvent(e);
			
			e = new PluginEvent(PluginEvent.START_GROUP, ba.position, 'Header');
			dispatchEvent(e);
			
			// Unknown header 0x00 0xBF
			e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'SOL Tag Header', '0x00 0xBF', 0x00FF00);
			ba.readShort();
			dispatchPluginEvent(e, ba.position);
			
			// Length of the rest of the file (filesize - 6)
			e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Tag Size', null, 0x00FF00, 50);
			var nLenData:int = ba.readUnsignedInt();
			e.value = nLenData;
			dispatchPluginEvent(e, ba.position);
			var tagEndPos:int = ba.position + nLenData;
			
			/*if (nLenFile != nLenData + 6) {
				throw new Error("Data Length Mismatch\nFile Length:" + nLenFile + " Data Length:" + (nLenData+6));
				return;
				//dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, "Data Length Mismatch\nFile Length:" + nLenFile + " Data Length:" + (nLenData+6)));
			}*/
			
			// Signature, 'TCSO'
			e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Signature', ba.readUTFBytes(4), 0x00FF00, 100);
			dispatchPluginEvent(e, ba.position);
			
			// Unknown, 6 bytes long 0x00 0x04 0x00 0x00 0x00 0x00
			e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Unknown Bytes', '0x00 0x04 0x00 0x00 0x00 0x00', 0x00FF00, -100);
			ba.readUTFBytes(6);
			dispatchPluginEvent(e, ba.position);
			
			// Read SOL Name
			e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Name', ba.readUTFBytes(ba.readUnsignedShort()), 0x00FF00, -50);
			dispatchPluginEvent(e, ba.position);
			
			// AMF Encoding
			e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'AMF Encoding', null, 0x00FF00, -50);
			_amfVersion = ba.readUnsignedInt();
			e.value = _amfVersion;
			dispatchPluginEvent(e, ba.position);
			
			e = new PluginEvent(PluginEvent.END_GROUP, ba.position);
			dispatchEvent(e);
			
			if(_amfVersion === ObjectEncoding.AMF0 || _amfVersion === ObjectEncoding.AMF3) {
				// Read body
				while(ba.position < tagEndPos) {
					//try {
						readVariable();
					//} catch(e:EOFError) {
						//trace(e.message);
					//	throw new Error(e.message);
					//	return;
					//}
				}
			} else {
				throw new Error("Not yet supported sol format, AMF version:" + _amfVersion);
				//dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, "Not yet supported sol format, AMF version:" + _amfVersion));
			}
			
			e = new PluginEvent(PluginEvent.END_GROUP, ba.position);
			dispatchEvent(e);
			
			// If more data
			if (ba.bytesAvailable > 1) {
				e = new PluginEvent(PluginEvent.START_GROUP, ba.position, 'Unknown Tag');
				dispatchEvent(e);
				
				e = new PluginEvent(PluginEvent.START_GROUP, ba.position, 'Header');
				dispatchEvent(e);
				
				// Unknown header 0x00 0xFF
				e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Unknown Tag Header', '0x00 0xFF', 0x00FF00);
				ba.readShort();
				dispatchPluginEvent(e, ba.position);
				
				// Length of the rest of the file (filesize - 6)
				e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Tag Size', null, 0x00FF00, 50);
				nLenData = ba.readUnsignedInt();
				e.value = nLenData;
				dispatchPluginEvent(e, ba.position);
				tagEndPos = ba.position + nLenData;
				
				e = new PluginEvent(PluginEvent.END_GROUP, ba.position);
				dispatchEvent(e);
				
				e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'String Length', null, 0x49D908);
				var l:int = ba.readUnsignedShort();
				e.value = l;
				dispatchPluginEvent(e, ba.position);
				
				e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'File Path', null, 0x00FF00, -75);
				e.value = ba.readUTFBytes(l);
				dispatchPluginEvent(e, ba.position);
				
				e = new PluginEvent(PluginEvent.END_GROUP, ba.position);
				dispatchEvent(e);
			}
		}
		
		protected function readVariable():void {
			if (ApplicationDomain.currentDomain.hasDefinition("com.coursevector.chimera.plugins.AMF3Plugin")){// && ApplicationDomain.currentDomain.hasDefinition("AMF0Plugin")) {
				
				var amfPlugin:Class;
				if (_amfVersion === ObjectEncoding.AMF0 && !amf0) {
					amfPlugin = getDefinitionByName("com.coursevector.chimera.plugins.AMF0Plugin") as Class;
					amf0 = new amfPlugin();
					amf0.addEventListener(PluginEvent.START_GROUP, pluginHandler);
					amf0.addEventListener(PluginEvent.END_GROUP, pluginHandler);
					amf0.addEventListener(PluginEvent.HIGHLIGHT, pluginHandler);
				}
				
				if (_amfVersion === ObjectEncoding.AMF3 && !amf3) {
					amfPlugin = getDefinitionByName("com.coursevector.chimera.plugins.AMF3Plugin") as Class;
					amf3 = new amfPlugin();
					amf3.addEventListener(PluginEvent.START_GROUP, pluginHandler);
					amf3.addEventListener(PluginEvent.END_GROUP, pluginHandler);
					amf3.addEventListener(PluginEvent.HIGHLIGHT, pluginHandler);
				}
				
				var e:PluginEvent = new PluginEvent(PluginEvent.START_GROUP, ba.position, 'Variable');
				dispatchEvent(e);
				
				var varName:String = "";
				var varVal:*;
				
				if (_amfVersion == ObjectEncoding.AMF3) {
					varName = amf3.readString(ba);
					varVal = amf3.readData(ba);
				} else {
					varName = amf0.readString(ba);
					varVal = amf0.readData(ba);
				}
				
				e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Variable End Byte', null, 0x00FF00, -75);
				ba.readByte(); // Ending byte
				dispatchPluginEvent(e, ba.position);
				
				e = new PluginEvent(PluginEvent.END_GROUP, ba.position);
				dispatchEvent(e);
				
				_data[varName] = varVal;
			} else {
				//o.alert = 'Please include AMF3 and AMF0 plugins';
			}
		}
		
		protected function pluginHandler(e:PluginEvent):void {
			dispatchEvent(e.clone());
		}
	}
}