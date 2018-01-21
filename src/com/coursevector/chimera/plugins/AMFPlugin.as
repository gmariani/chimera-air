package com.coursevector.chimera.plugins {
	
	import flash.errors.EOFError;
	import flash.events.ErrorEvent;
	import flash.events.EventDispatcher;
	import flash.net.ObjectEncoding;
	import flash.system.ApplicationDomain;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.getDefinitionByName;
	
	public class AMFPlugin extends Plugin {
		
		protected var _data:Object;
		protected var ba:ByteArray = new ByteArray();
		protected var _amfVersion:uint;
		protected var _versionInfo:String;
		protected var amf0:AMF0Plugin;
		protected var amf3:AMF3Plugin;
		
		public function AMFPlugin() {
			super();
		}
		
		override public function parse(ba:ByteArray):void {
			if (ApplicationDomain.currentDomain.hasDefinition("com.coursevector.chimera.plugins.AMF3Plugin")){// && ApplicationDomain.currentDomain.hasDefinition("AMF0Plugin")) {
				var amfPlugin:Class;
				if (_amfVersion === ObjectEncoding.AMF0 && !amf0) {
					amfPlugin = getDefinitionByName("com.coursevector.chimera.plugins.AMF0Plugin") as Class;
					amf0 = new amfPlugin();
					amf0.addEventListener(PluginEvent.START_GROUP, pluginHandler);
					amf0.addEventListener(PluginEvent.END_GROUP, pluginHandler);
					amf0.addEventListener(PluginEvent.HIGHLIGHT, pluginHandler);
				}
				
			} else {
				//o.alert = 'Please include AMF3 and AMF0 plugins';
			}
			
			_data = { };
			_data.headers = [];
			_data.bodies = [];
			
			ba.endian = Endian.BIG_ENDIAN;
			this.ba = ba;
			readHeader();
			readBody();
		}
		
		protected function readHeader():void {
			var e:PluginEvent = new PluginEvent(PluginEvent.START_GROUP, ba.position, 'AMF Header');
			dispatchEvent(e);
			
			// Read Header
			e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'AMF Encoding', null, 0x00FF00, -50);
			_amfVersion = ba.readUnsignedShort();
			e.value = _amfVersion;
			dispatchPluginEvent(e, ba.position);
			
			switch(_amfVersion) {
				case ObjectEncoding.AMF0:
					_versionInfo = "Flash Player 8 and Below";
					break;
				case 1: // There is no AMF1 but FMS uses it for some reason, hence special casing.
					_versionInfo = "Flash Media Server";
					break;
				case ObjectEncoding.AMF3:
					_versionInfo = "Flash Player 9+";
					break;
			}
			
			if (_amfVersion != ObjectEncoding.AMF0 && _amfVersion != ObjectEncoding.AMF3) {
				//Unsupported AMF version {version}.
				throw new Error("Unsupported AMF version " + _amfVersion);     
			}
			
			e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Number of Headers', null, 0x00FF00, -50);
			var numHeaders:uint = ba.readUnsignedShort(); //  find the total number of header elements return
			e.value = numHeaders;
			dispatchPluginEvent(e, ba.position);
			while (numHeaders--) {
				//amf0.reset();
				
				e = new PluginEvent(PluginEvent.START_GROUP, ba.position, 'Header');
				dispatchEvent(e);
				
				e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Name', null, 0x00FF00, -50);
				var name:String = ba.readUTF();
				e.value = name;
				dispatchPluginEvent(e, ba.position);
				
				e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Required Flag', null, 0x00FF00, -50);
				var required:Boolean = !!ba.readUnsignedByte(); // find the must understand flag
				e.value = required;
				dispatchPluginEvent(e, ba.position);
				
				e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Length', null, 0x00FF00, -50);
				var length:uint = ba.readUnsignedInt(); // grab the length of the header element, -1 if unknown
				e.value = formatSize(length);
				dispatchPluginEvent(e, ba.position);
				
				var data:* = amf0.readData(ba); // turn the element into real data
				
				e = new PluginEvent(PluginEvent.END_GROUP, ba.position);
				dispatchEvent(e);
				
				_data.headers.push({ name:name, mustUnderstand:required, length:formatSize(length), data:data }); // save the name/value into the headers array
			}
			
			e = new PluginEvent(PluginEvent.END_GROUP, ba.position);
			dispatchEvent(e);
		}
		
		protected function readBody():void {
			// Read Body
			var e:PluginEvent = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Number of Bodies', null, 0x00FF00, -50);
			var numBodies:uint = ba.readUnsignedShort(); //  find the total number of body elements
			e.value = numBodies;
			dispatchPluginEvent(e, ba.position);
			
			while (numBodies--) {
				//amf0.reset();
				
				e = new PluginEvent(PluginEvent.START_GROUP, ba.position, 'Body');
				dispatchEvent(e);
				
				e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Target URI', null, 0x00FF00, -50);
				var targetURI:String = ba.readUTF(); // When the message holds a response from a remote endpoint, the target URI specifies which method on the local client (i.e. AMF request originator) should be invoked to handle the response.
				e.value = targetURI;
				dispatchPluginEvent(e, ba.position);
				
				e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Response URI', null, 0x00FF00, -50);
				var responseURI:String = ba.readUTF(); // The response's target URI is set to the request's response URI with an '/onResult' suffix to denote a success or an '/onStatus' suffix to denote a failure.
				e.value = responseURI;
				dispatchPluginEvent(e, ba.position);
				
				e = new PluginEvent(PluginEvent.HIGHLIGHT, ba.position, 'Length', null, 0x00FF00, -50);
				var length:uint = ba.readUnsignedInt(); // grab the length of the body element, -1 if unknown
				e.value = formatSize(length);
				dispatchPluginEvent(e, ba.position);
				
				var data:* = amf0.readData(ba); // turn the element into real data
				
				e = new PluginEvent(PluginEvent.END_GROUP, ba.position);
				dispatchEvent(e);
				
				_data.bodies.push({ targetURI:targetURI, responseURI:responseURI, length:formatSize(length), data:data }); // add the body element to the body object
			}
		}
		
		protected function formatSize(bytes:int):String {
			
			// Get size precision (number of decimal places from the preferences)
			// and make sure it's within limits.
			var sizePrecision:uint = 2;
			sizePrecision = (sizePrecision > 2) ? 2 : sizePrecision;
			sizePrecision = (sizePrecision < -1) ? -1 : sizePrecision;
			
			if (sizePrecision == -1) return bytes + " B";
			
			var a:Number = Math.pow(10, sizePrecision);
			
			if (bytes == -1/* || bytes == undefined*/) {
				return "-1";
			/*} else if(bytes == undefined) {
				return "?";*/
			} else if (bytes == 0) {
				return "0";
			} else if (bytes < 1024) {
				return bytes + " B";
			} else if (bytes < (1024*1024)) {
				return Math.round((bytes/1024)*a)/a + " KB";
			} else {
				return Math.round((bytes/(1024*1024))*a)/a + " MB";
			}
		}
		
		protected function pluginHandler(e:PluginEvent):void {
			dispatchEvent(e.clone());
		}
	}
}