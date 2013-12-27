/*********************************************************************************
 *
 *  ACTSONE COMPANY
 *  Copyright 2013 Actsone 
 *  All Rights Reserved.
 *
 *	This program is free software: you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License as published by
 *	the Free Software Foundation, either version 3 of the License, or
 *	(at your option) any later version.
 *
 *	This program is distributed in the hope that it will be useful,
 *	but WITHOUT ANY WARRANTY; without even the implied warranty of
 *	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *	GNU General Public License for more details.
 *
 *	You should have received a copy of the GNU General Public License
 *	along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 *************************************************************************************/
package kr.co.actsone.itemRenderers
{
	import flash.display.DisplayObject;
	import flash.geom.Rectangle;
	
	import kr.co.actsone.common.ColumnType;
	import kr.co.actsone.common.Global;
	import kr.co.actsone.common.GridOneManager;
	import kr.co.actsone.controls.advancedDataGridClasses.ExAdvancedDataGridColumn;
	import kr.co.actsone.summarybar.SummaryBar;
	import kr.co.actsone.summarybar.SummaryBarConstant;
	import kr.co.actsone.summarybar.SummaryBarStyle;
	
	import mx.core.IUITextField;
	import mx.core.UITextField;
	
	public class TotalRenderer extends ExUIComponent
	{
		protected var label:IUITextField;
		 
		/******************************************************************************************
		 * constructor
		 ******************************************************************************************/
		public function TotalRenderer()
		{
			super();
			tabEnabled = false;
			this.setStyle('verticalAlign','middle');
		}
		
		/******************************************************************************************
		 * create children
		 ******************************************************************************************/
		override protected function createChildren():void
		{
			super.createChildren();
			
			createLabel(-1);
		}
		
		/******************************************************************************************
		 * create label
		 ******************************************************************************************/
		protected function createLabel(childIndex:int):void
		{
			if (!label)
			{
				label = IUITextField(createInFontContext(UITextField));
				label.styleName = this;
				
				if (childIndex == -1)
					addChild(DisplayObject(label));
				else 
					addChildAt(DisplayObject(label), childIndex);
			}
		}
		
		/******************************************************************************************
		 * remove label
		 ******************************************************************************************/
		protected function removeLabel():void
		{
			if (label != null)
			{
				removeChild(DisplayObject(label));
				label = null;
			}
		}
		
		/******************************************************************************************
		 * commit property
		 ******************************************************************************************/
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if(this.label)
			{
				if (data && column && column.width > 0)
				{
					if(data[SummaryBarConstant.TOTAL])
					{
						label.width = column.width;
						var originalText : String = '';
						var bkText : String ='';
						//fill summary column
						//get current summary bar
						var summaryBar : SummaryBar = listOwner.lstSummaryBar[data[SummaryBarConstant.SUMMARY_BAR_KEY]];
						//set label total
						if(data[SummaryBarConstant.SUMMARY_MERGE_COLUMN] == column.dataField)
						{
							originalText = summaryBar.strText;
						}
						if(summaryBar != null && column !=null && column.totalColumn)
						{
							//fill data summary column
							if(summaryBar.functionList[column.dataField] == SummaryBarConstant.FUNC_CUSTOM)
							{
								if(column.type == ColumnType.NUMBER)
								{
									if(listOwner.summaryBar.isTotalCol(summaryBar,column))
									{
										originalText = listOwner.summaryBar.formatBaseOnPatternTotal(column,data[column.dataField],data);
									}
								}
								else
								{
									if((column.positionTotalChange[data[SummaryBarConstant.SUMMARY_BAR_KEY] + '_' + column.dataField + '_0' ] != null)  && (summaryBar.functionList[column.dataField] == SummaryBarConstant.FUNC_CUSTOM))
									{
										if(isNaN(Number(column.positionTotalChange[data[SummaryBarConstant.SUMMARY_BAR_KEY] + '_' + column.dataField + '_0']))) // data type is string --> no need calculating
											originalText = column.positionTotalChange[data[SummaryBarConstant.SUMMARY_BAR_KEY] + '_' + column.dataField + '_0'];
										else
										{
											if(column.formatType != null && column.formatType[data[SummaryBarConstant.SUMMARY_BAR_KEY]] != null)
												originalText = listOwner.summaryBar.formatBaseOnPatternTotal(column,column.positionTotalChange[data['strSummaryBarKey'] + '_' + column.dataField + '_0'],data);
											else
												originalText = column.positionTotalChange[data[SummaryBarConstant.SUMMARY_BAR_KEY] + '_' + column.dataField + '_0'];
										}
									}
									else
									{
										originalText ='';
									}
								}
							}
							else
							{
								if(column.type != ColumnType.NUMBER)
									data[column.dataField] = renderLabelFuncOfSummaryBar(data,column);
								if(listOwner.summaryBar.isTotalCol(summaryBar,column)) // if this is a summary bar column
								{
									if(isNaN(Number(data[column.dataField]))) // using for case of user set text is not number
										originalText = data[column.dataField];
									else
										originalText = listOwner.summaryBar.formatBaseOnPatternTotal(column,data[column.dataField],data);									
								}
							}
						}
						this.label.text = originalText;
					}
					
					var dataTips:Boolean = listOwner.showDataTips;
					if (column.showDataTips == true)
						dataTips = true;
					if (column.showDataTips == false)
						dataTips = false;
					if (dataTips)
					{
						if (!(data is ExAdvancedDataGridColumn) && (label.textWidth > label.width
							|| column.dataTipFunction || column.dataTipField 
							|| listOwner.dataTipFunction || listOwner.dataTipField))
						{
							toolTip = column.itemToDataTip(data);
						}
						else
						{
							toolTip = null;
						}
					}
					else
					{
						toolTip = null;
					}
				}
				else
				{
					label.text = " ";
					toolTip = null;
					label.width = 0;
				}				
			}
			invalidateDisplayList();
		}
		
		/******************************************************************************************
		 * update display list
		 ******************************************************************************************/
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			var truncated:Boolean;
			truncated = label.truncateToFit();				
			
			if (!toolTipSet)
				super.toolTip = truncated ? this.label.text : null;
			
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			this.label.move(0,0);
			var startX:Number = 0;
			if(this.listOwner && this.listOwner.nCellPadding)
			{
				startX += this.listOwner.nCellPadding;
			}
			var t:String = getMinimumText(label.text);
			var textFieldBounds:Rectangle = measureTextFieldBounds(t);
			label.height = textFieldBounds.height;
			label.setActualSize(unscaledWidth - startX, label.height);
			
			var textAlign:String = getStyle("textAlign");
			if (textAlign == "left")
			{
				label.x = startX;
			}
			else if (textAlign == "right")
			{
				label.x = unscaledWidth - startX - label.width + 2; // 2 for gutter
			}
			else
			{
				label.x = (unscaledWidth - label.width) / 2  - startX;
			}
			
			var verticalAlign:String = getStyle("verticalAlign");
			if (verticalAlign == "top")
			{
				label.y = 0;
			}
			else if (verticalAlign == "bottom")
			{
				label.y = unscaledHeight - label.height + 2; // 2 for gutter
			}
			else
			{
				label.y = (unscaledHeight - label.height) / 2;
			}
			
			drawStrikeThrough(this.label);
			
			//because some reason, this style is cleaned. We need to re-set it again.
			var styleValue:String = getSummaryBarCellStyle('textDecoration');
			this.setStyle('textDecoration',styleValue);
		}
		
		/******************************************************************************************
		 * Apply color of cell
		 * @author Duong Pham
		 ******************************************************************************************/
		override public function validateNow():void
		{
			super.validateNow();
			if (data && parent)
			{
				var newColor:Number = getCurentColor();
				var oldColor:* = label.textColor;
				if (oldColor != newColor)
				{
					label.setColor(newColor);
					invalidateDisplayList();
				}
			}
		}
		
		/******************************************************************************************
		 * Get accessibility name for screen reader
		 * @author Thuan
		 ******************************************************************************************/
		override public function getAccessibilityName():String
		{
			//return "Component is Total. Value is " + this.label.text;
			var strReader:String = this.column.strAccessReader;
			
			if (strReader && strReader.length > 0) // Parse value in strAccessReader 
			{
				if (strReader.indexOf(Global.ACCESS_READER_CONTROLTYPE) > -1)
				{
					strReader = strReader.replace(Global.ACCESS_READER_CONTROLTYPE, Global.ACCESS_READER_TOTAL);
					if (strReader.indexOf(Global.ACCESS_READER_CELLVALUE) > -1)
						strReader = strReader.replace(Global.ACCESS_READER_CELLVALUE, this.label.text);
				}
				else // don't have control type in strAccessReader
				{
					if (strReader.indexOf(Global.ACCESS_READER_CELLVALUE) > -1)
						strReader = strReader.replace(Global.ACCESS_READER_CELLVALUE, this.label.text);
				}
				//				trace("Label Renderer strReader != null: " + strReader);
			}
			else // make column default information
			{
				strReader = Global.ACCESS_READER_COLUMN_DEFAULT + " " + Global.ACCESS_READER_CONTROL + " " + 
					Global.ACCESS_READER_TOTAL + " " + Global.ACCESS_READER_CELL + " " + this.label.text;
				//				trace("Label Renderer strReader == null: " + strReader);
			}
			return strReader;
		}
		
		/**************************************************************************
		 * verify cell is drawn strike through text or not
		 * @author Duong Pham 
		 **************************************************************************/
		override protected function isStrikeThroughText():Boolean
		{
			var summaryBarStyle : SummaryBarStyle = column.summaryBarStyle[data[SummaryBarConstant.SUMMARY_BAR_KEY]];
			if(summaryBarStyle && summaryBarStyle.totalFontCLine)
				_isStrikeThrough = summaryBarStyle.totalFontCLine;				
			else 	
				_isStrikeThrough = super.isStrikeThroughText();
			return _isStrikeThrough;
		}
		
		/*************************************************************
		 * function support label function of column Text type.
		 * It will support 2 cases
		 * - calculate in sub total
		 * - calculate in total
		 * @param item Object data
		 * @param column ExAdvancedDataGridColumn
		 * @author Duong Pham
		 * ***********************************************************/
		public function renderLabelFuncOfSummaryBar(item : Object, column:ExAdvancedDataGridColumn): String
		{
			var rs : String ="";
			//var value : Number = 0;
			var value : String=item[column.dataField];
			var count : int =0;
			if(column.subToltalColumn || column.totalColumn)
			{
				var currentSummaryBarKey : String;
				var currentSummaryBar : SummaryBar;
				var strFunc : String;
				var currentIndex : int = 0; 
				
				var typeSummarybar : String;
				if (item[SummaryBarConstant.TOTAL] != null)  // total row
				{
					currentSummaryBarKey = item[SummaryBarConstant.SUMMARY_BAR_KEY];
					currentSummaryBar  = listOwner.lstSummaryBar[currentSummaryBarKey] as SummaryBar;
					if(currentSummaryBar.functionList[column.dataField] != null)
						strFunc  = (currentSummaryBar.functionList[column.dataField]).toString().toLowerCase();
					typeSummarybar = currentSummaryBar.strFunction;
					
					if(column.positionTotalChange[currentSummaryBarKey + '_' + column.dataField + '_' + 0] != null && typeSummarybar == SummaryBarConstant.FUNC_CUSTOM)
					{
						value = column.positionTotalChange [currentSummaryBarKey + '_' + column.dataField + '_' +0].toString();
					}
					else
					{
						if(strFunc != SummaryBarConstant.FUNC_CUSTOM)
							value = listOwner.summaryBar.calculateTotal(strFunc,currentSummaryBarKey,column).toString();
						else
							value = '0';
					}
				}
				else // data row
				{
					//value = Number(item[column.dataField].toString());
					value = item[column.dataField].toString();
				}
				item[column.dataField] = value;
			}
			//			return this.datagrid.summaryBarManager.formatBaseOnPatternTotal(column,value,item);
			return value;
		}
	}
}