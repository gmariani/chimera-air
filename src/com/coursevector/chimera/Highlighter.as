package com.coursevector.chimera {
	
	import com.coursevector.chimera.HighlightBlock;
	import com.coursevector.chimera.HighlightGroup;
	import com.coursevector.chimera.plugins.PluginEvent;
	
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.utils.ByteArray;
	
	import mx.core.IVisualElementContainer;
	import mx.core.UIComponent;

	public class Highlighter extends EventDispatcher {
		
		public var offsetPoint:Point = new Point(1, 2);
		
		private var arrBlocks:Array = [];
		private var arrGroups:Array = [];
		private var arrGroupsData:Array = [];
		private var _root:IVisualElementContainer;
		private var ba:ByteArray;
		private var columns:int;
		private var rows:int;
		private var charHeight:Number;
		private var charWidth:Number;
		private var _block:HighlightBlock;
		
		public function Highlighter(target:IVisualElementContainer, ba:ByteArray, columns:int, rows:int, charHeight:Number, charWidth:Number) {
			_root = target;
			
			this.ba = ba;
			this.columns = columns;
			this.rows = rows;
			this.charHeight = charHeight;
			this.charWidth = charWidth;
		}
		
		public function get currentBlock():HighlightBlock {
			return _block;
		}
		
		public function get blocks():Array {
			return arrBlocks;
		}
		
		public function get groups():Array {
			return arrGroups;
		}
		
		public function clear():void {
			while (arrBlocks.length) {
				_root.removeElement(arrBlocks.pop());
			}
			
			while (arrGroups.length) {
				_root.removeElement(arrGroups.pop());
			}
			arrGroupsData = [];
		}
		
		public function startGroup(index:uint, name:String):void {
			arrGroupsData.push({startIndex:index, name:name, items:[]});
		}
		
		public function endGroup(index:uint):void {
			var o:Object = arrGroupsData.pop();
			var hlGroup:HighlightGroup = new HighlightGroup(ba, columns, rows, charHeight, charWidth);
			hlGroup.offsetPoint = offsetPoint;
			hlGroup.highLightDraw(o.startIndex, index, 0xff0000, 0);
			hlGroup.includeInLayout = false;
			hlGroup.alpha = 0;
			_root.addElementAt(hlGroup, 0);
			hlGroup.index = arrGroups.length;
			arrGroups.push(hlGroup);
			
			for (var i:int = 0; i < o.items.length; i++) {
				var hlBlock:HighlightBlock = o.items[i];
				hlBlock.group = hlGroup;
				hlBlock.toolTip = '<font size="+3"><b>- ' + o.name + ' -</b></font><br/>' + hlBlock.toolTip;
			}
		}
		
		public function showBlock(data:PluginEvent):void {
			var hlBlock:HighlightBlock = new HighlightBlock(ba, columns, rows, charHeight, charWidth);
			hlBlock.offsetPoint = offsetPoint;
			hlBlock.highLightDraw(data.startIndex, data.endIndex, data.color, data.brightness);
			hlBlock.includeInLayout = false;
			hlBlock.alpha = 0;
			hlBlock.addEventListener(MouseEvent.MOUSE_OVER, onMouseBlock);
			hlBlock.addEventListener(MouseEvent.MOUSE_OUT, onMouseBlock);
			var str:String = '<font size="+2"><b>' + data.name + '</b></font>';
			var strData:String = String(data.value);
			
			// Fix XML embedded in HTML
			strData = strData.split("<br/>").join("$$$$BR$$$$");
			strData = strData.split("<").join("&lt;");
			strData = strData.split("$$$$BR$$$$").join("<br/>");
			//strData = strData.replace('<', '&#60;');
			
			// Limit huge tooltips
			if (strData.length > 400) strData = strData.substring(0, 400) + '...';
			
			// Concact tooltip text
			if (data.value != undefined && data.value != null) str += ' : ' + strData;
			str += '<br/><br/><font size="-2">startIndex: ' + data.startIndex + "<br>endIndex: " + data.endIndex + '<br>length: ' + (data.endIndex - data.startIndex).toString() + '</font>';
			hlBlock.toolTip = str;
			_root.addElement(hlBlock);
			
			if (arrGroupsData.length > 0) arrGroupsData[arrGroupsData.length - 1].items.push(hlBlock);
			
			hlBlock.index = arrBlocks.length;
			arrBlocks.push(hlBlock);
		}
		
		private function onMouseBlock(event:MouseEvent):void {
			_block = event.currentTarget as HighlightBlock;
			dispatchEvent(event.clone());
		}
	}
}