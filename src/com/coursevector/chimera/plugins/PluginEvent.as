package com.coursevector.chimera.plugins {
	
	import flash.events.Event;
	
	public class PluginEvent extends Event {
		
		public static var HIGHLIGHT:String = 'highlight';
		public static var START_GROUP:String = 'startGroup';
		public static var END_GROUP:String = 'endGroup';
		
		public var name:String = '';
		public var value:* = '';
		public var startIndex:uint = 0;
		public var endIndex:uint = 0;
		public var color:uint = 0x000000;
		public var brightness:int = 0;
		
		public function PluginEvent(type:String='highlight', startIndex:uint=0, name:String='', value:*='', color:uint=0x000000, brightness:int=0, bubbles:Boolean=false, cancelable:Boolean=false) {
			super(type, bubbles, cancelable);
			
			this.name = name;
			this.value = value;
			this.startIndex = startIndex;
			this.endIndex = endIndex;
			this.color = color;
			this.brightness = brightness;
		}
		
		override public function clone():Event {
			var e:PluginEvent = new PluginEvent(type, startIndex, name, value, color, brightness, bubbles, cancelable);
			e.endIndex = this.endIndex;
			return e;
		}
		
		override public function toString():String {
			return '[Event type="' + this.type + '" startIndex=' + this.startIndex + ' endIndex=' + this.endIndex + ' name="' + this.name + '" value="' + this.value + '" color=' + this.color + ' brightness=' + this.brightness + ' bubbles=false cancelable=false eventPhase=2]';
		}
	}
}