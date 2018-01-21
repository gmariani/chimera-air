package com.coursevector.chimera {
	
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;

	public class HighlightGroup extends HighlightBlock {
		
		public function HighlightGroup(ba:ByteArray, columns:int, rows:int, charHeight:Number, charWidth:Number) {
			super(ba, columns, rows, charHeight, charWidth);
			
			this.mouseEnabled = false;
		}
		
		override protected function normalDraw(beginIndex:uint, endIndex:uint, color:int):void {
			var beginLineIndex:uint = getLineIndex(beginIndex);
			var endLineIndex:uint = getLineIndex(endIndex);
			var disLineNum:uint = endLineIndex - beginLineIndex;
			var r:Rectangle;
			var p:Point;
			var square_commands:Vector.<int> = new Vector.<int>();
			var square_coord:Vector.<Number> = new Vector.<Number>();
			
			if(disLineNum < 1) {
				r = drawSingleLine(beginIndex, endIndex, color);
				
				// 1 moveTo command followed by 3 lineTo commands
				square_commands.push(1, 2, 2, 2, 2);
				
				// use the Vector array push() method to add a set of coordinate pairs
				square_coord.push(r.left,r.top, r.right,r.top, r.right,r.bottom, r.left,r.bottom, r.left,r.top);
				graphics.lineStyle(1, color);
				graphics.drawPath(square_commands, square_coord);
				return;
			}
			
			r = drawSingleLine(beginIndex, getRowOffset(beginLineIndex) + columns - 1, color);
			p = new Point(r.left, r.bottom);
			square_commands.push(1, 2, 2, 2);
			square_coord.push(r.left,r.bottom, r.left,r.top, r.right,r.top, r.right,r.bottom);
			
			for(var i:uint = beginLineIndex + 1; i < endLineIndex; i++) {
				r = drawSingleLine(getRowOffset(i), getRowOffset(i) + columns - 1, color);
				square_commands.push(2);
				square_coord.push(r.right,r.bottom);
			}
			
			r = drawSingleLine(getRowOffset(endLineIndex), endIndex, color);
			
			square_commands.push(2, 2, 2, 2, 2);
			square_coord.push(r.right,r.top, r.right,r.bottom, r.left,r.bottom, r.left,p.y, p.x,p.y);
			graphics.lineStyle(1, color);
			graphics.drawPath(square_commands, square_coord);
		}
		
		override protected function drawSingleLine(beginIndex:int, endIndex:int, color:int):Rectangle {
			var lineIndex:uint = getLineIndex(beginIndex);
			if ((getLineIndex(endIndex) - lineIndex) < 1) {
				return new Rectangle((beginIndex - getRowOffset(lineIndex)) * charWidth + _offsetPoint.x, lineIndex * charHeight + _offsetPoint.y, ((endIndex + 1) - beginIndex) * charWidth, charHeight);
			} else {
				throw new Error("drawSingleLine:disLineNum >= 1.");
			}
		}
	}
}