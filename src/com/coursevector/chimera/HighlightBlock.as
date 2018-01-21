package com.coursevector.chimera {
	
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	
	import mx.flash.UIMovieClip;
	import mx.utils.ColorUtil;
	
	import spark.components.HGroup;
	
	public class HighlightBlock extends UIMovieClip {
		
		protected var _offsetPoint:Point;
		protected var _group:HighlightGroup;
		protected var ba:ByteArray;
		protected var columns:int;
		protected var rows:int;
		protected var charHeight:Number;
		protected var charWidth:Number;
		
		public var index:int = 0;
		
		public function HighlightBlock(ba:ByteArray, columns:int, rows:int, charHeight:Number, charWidth:Number) {
			super();
			
			_offsetPoint = new Point(0, 0);
			this.ba = ba;
			this.columns = columns;
			this.rows = rows;
			this.charHeight = charHeight;
			this.charWidth = charWidth;
		}
		
		public function set offsetPoint(value:Point):void {
			_offsetPoint = value;
		}
			
		public function get offsetPoint():Point {
			return _offsetPoint;
		}
		
		public function set group(value:HighlightGroup):void {
			_group = value;
		}
		
		public function get group():HighlightGroup {
			return _group;
		}
		
		public function highLightDraw(beginIndex:int, endIndex:int, color:uint, brightness:int):void {
			endIndex--;
			var beginValidIndex:int = getValidBeginCharIndex(beginIndex);
			var endValidIndex:int = getValidEndCharIndex(endIndex);
			
			if(beginValidIndex == -1 || endValidIndex == -2) {
				//throw new Error("Invalid value");
				return;
			}
			
			color = ColorUtil.adjustBrightness(color, brightness);
			if(beginValidIndex <= endValidIndex) normalDraw(beginValidIndex, endValidIndex, color);
		}
		
		protected function getValidBeginCharIndex(beginIndex:uint):int {
			var len:uint = ba.length;
			if(beginIndex < 0 || beginIndex > len - 1) return -1;
			
			var line:uint = getLineIndex(beginIndex);
			if(line < 0) {
				line = 0;
				return getRowOffset(line);
			}
			
			return beginIndex;
		}
		
		protected function getValidEndCharIndex(endIndex:uint):int {
			var len:uint = ba.length;
			if (endIndex < 0 || endIndex > len - 1) return -2;
			
			var line:int = getLineIndex(endIndex);
			if(line > rows) {
				line = rows;
				return getRowOffset(line) + columns;
			}
			
			return endIndex;
		}
		
		/**
		 * Guesses the line index based on byte index
		 */
		protected function getLineIndex(index:int):int {
			return index / columns;
		}
		
		/**
		 * Get the first index of a specific line of text
		 */
		protected function getRowOffset(rowIndex:int):int {
			return (rowIndex * columns);
		}
		
		protected function normalDraw(beginIndex:uint, endIndex:uint, color:int):void {
			var beginLineIndex:uint = getLineIndex(beginIndex);
			var endLineIndex:uint = getLineIndex(endIndex);
			var disLineNum:uint = endLineIndex - beginLineIndex;
			
			if(disLineNum < 1) {
				drawSingleLine(beginIndex, endIndex, color);
				return;
			}
			
			drawSingleLine(beginIndex, getRowOffset(beginLineIndex) + columns - 1, color);
			
			for(var i:uint = beginLineIndex + 1; i < endLineIndex; i++) {
				drawSingleLine(getRowOffset(i), getRowOffset(i) + columns - 1, color);
			}
			
			drawSingleLine(getRowOffset(endLineIndex), endIndex, color);
		}
		
		protected function drawSingleLine(beginIndex:int, endIndex:int, color:int):Rectangle {
			var beginLineIndex:int = getLineIndex(beginIndex);
			var endLineIndex:int = getLineIndex(endIndex);
			var disLineNum:int = endLineIndex - beginLineIndex;
			
			if (disLineNum < 1) {
				var lineIndex:uint = getLineIndex(beginIndex);
				var rowStartIndex:int = getRowOffset(lineIndex);
				var rect:Rectangle = new Rectangle((beginIndex - rowStartIndex) * charWidth, lineIndex * charHeight, ((endIndex + 1) - beginIndex) * charWidth, charHeight);
				
				graphics.beginFill(color, 0.35); 
				//graphics.lineStyle(1, color, 0.65, true);
				graphics.drawRoundRectComplex(_offsetPoint.x + rect.x, _offsetPoint.y + rect.y, rect.width, rect.height, 0, 0, 0, 0);
				graphics.endFill();
				return rect;
			} else {
				throw new Error("drawSingleLine:disLineNum >= 1.");
			}
		}

		/*override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			trace('updateDisplayList2');
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			for(var i:int = 0; i < arrHighlights.length; i++) {
				var o:Object = arrHighlights[i];
				var data:Object = o.data;
				trace('-------------------');
				trace(data.desc);
				normalDraw(data.startIndex, data.endIndex, data.color);
			}
		}*/
	}
}