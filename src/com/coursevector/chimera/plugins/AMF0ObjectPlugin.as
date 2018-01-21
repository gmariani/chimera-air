package com.coursevector.chimera.plugins {
	
	import flash.errors.EOFError;
	import flash.events.ErrorEvent;
	import flash.events.EventDispatcher;
	import flash.net.ObjectEncoding;
	import flash.system.ApplicationDomain;
	import flash.utils.ByteArray;
	import flash.utils.getDefinitionByName;
	
	public class AMF0ObjectPlugin extends Plugin {
		
		protected var _data:Object;
		protected var ba:ByteArray = new ByteArray();
		protected var amf0:AMF0Plugin;
		
		public function AMF0ObjectPlugin() {
			super();
		}
		
		override public function parse(ba:ByteArray):void {
			_data = { };
			this.ba = ba;
			
			var e:PluginEvent = new PluginEvent(PluginEvent.START_GROUP, ba.position, 'Header');
			dispatchEvent(e);
			
			if (ApplicationDomain.currentDomain.hasDefinition("com.coursevector.chimera.plugins.AMF0Plugin")) {
				if (!amf0) {
					var amfPlugin:Class = getDefinitionByName("com.coursevector.chimera.plugins.AMF0Plugin") as Class;
					amf0 = new amfPlugin();
					amf0.addEventListener(PluginEvent.START_GROUP, pluginHandler);
					amf0.addEventListener(PluginEvent.END_GROUP, pluginHandler);
					amf0.addEventListener(PluginEvent.HIGHLIGHT, pluginHandler);
				}
				
				_data = amf0.readData(ba);
				
				e = new PluginEvent(PluginEvent.END_GROUP, ba.position);
				dispatchEvent(e);
			}
		}
		
		protected function pluginHandler(e:PluginEvent):void {
			dispatchEvent(e.clone());
		}
	}
}