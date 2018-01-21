package com.coursevector.chimera.plugins {
	
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;
	
	public class Plugin extends EventDispatcher	{
		
		public function parse(ba:ByteArray):void {
			//
		}
		
		protected function dispatchPluginEvent(e:PluginEvent, endIndex:uint):void {
			e.endIndex = endIndex;
			dispatchEvent(e);
		}
	}
}