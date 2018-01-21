package com.coursevector.chimera.plugins {
	
	import flash.errors.EOFError;
	import flash.events.ErrorEvent;
	import flash.events.EventDispatcher;
	import flash.net.ObjectEncoding;
	import flash.system.ApplicationDomain;
	import flash.utils.ByteArray;
	import flash.utils.getDefinitionByName;
	
	public class AMF3ObjectPlugin extends Plugin {
		
		protected var _data:Object;
		protected var ba:ByteArray = new ByteArray();
		protected var amf3:AMF3Plugin;
		
		public function AMF3ObjectPlugin() {
			super();
		}
		
		override public function parse(ba:ByteArray):void {
			_data = { };
			this.ba = ba;
			
			var e:PluginEvent = new PluginEvent(PluginEvent.START_GROUP, ba.position, 'Header');
			dispatchEvent(e);
			
			if (ApplicationDomain.currentDomain.hasDefinition("com.coursevector.chimera.plugins.AMF3Plugin")) {
				if (!amf3) {
					var amfPlugin:Class = getDefinitionByName("com.coursevector.chimera.plugins.AMF3Plugin") as Class;
					amf3 = new amfPlugin();
					amf3.addEventListener(PluginEvent.START_GROUP, pluginHandler);
					amf3.addEventListener(PluginEvent.END_GROUP, pluginHandler);
					amf3.addEventListener(PluginEvent.HIGHLIGHT, pluginHandler);
				}
				
				_data = amf3.readData(ba);
				
				e = new PluginEvent(PluginEvent.END_GROUP, ba.position);
				dispatchEvent(e);
			}
		}
		
		protected function pluginHandler(e:PluginEvent):void {
			dispatchEvent(e.clone());
		}
	}
}