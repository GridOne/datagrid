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

package kr.co.actsone.summarybar
{
	
	import com.adobe.utils.DictionaryUtil;
	
	import flash.utils.Dictionary;
	
	import kr.co.actsone.common.ColumnType;
	import kr.co.actsone.common.DataGridManager;
	import kr.co.actsone.common.Global;
	import kr.co.actsone.common.LabelFunctionLib;
	import kr.co.actsone.controls.ExAdvancedDataGrid;
	import kr.co.actsone.controls.advancedDataGridClasses.ExAdvancedDataGridColumn;
	import kr.co.actsone.footer.FooterBar;
	
	import mx.collections.ArrayCollection;
	import mx.formatters.CurrencyFormatter;
	import mx.formatters.NumberFormatter;
	import mx.utils.StringUtil;
	
	public class SummaryBarManager
	{
		public var columnMergeList:String;
		public var lstColMergeHasSubTotal : ArrayCollection;		
		public var currentSummaryBarKey : String;		
		
//		public var lstSubTotal : Dictionary;
//		public var lstTotal : Dictionary;
		public var lstMergeColumn : ArrayCollection;
		public var index:int=0;
		
		protected var gridOne:GridOne;
		protected var labelFuncLib:LabelFunctionLib;
		
		public function SummaryBarManager(app:Object):void
		{
			gridOne=app as GridOne;
			labelFuncLib = new LabelFunctionLib(gridOne);
		}
		
		public function get datagrid():ExAdvancedDataGrid
		{
			return gridOne.datagrid;
		}	
		
		public function get dgManager():DataGridManager
		{
			return gridOne.dgManager;
		}
		
		/*************************************************************
		 * has summary bar
		 * @return Boolean
		 * author: Hoang Pham
		 * ***********************************************************/
		public function hasSummaryBar():Boolean
		{
			var rs : Boolean = false;
			if(this.datagrid.hasSubTotal || this.datagrid.hasTotal || this.datagrid.hasTotalColumn)
				rs = true;
			return rs;
		}
//		
		/*************************************************************
		 * clear summary bar
		 * @param gridone : GridOne
		 * author: Hoang Pham
		 * ***********************************************************/
		public function clearSummaryBar():void
		{
			index = 0;
			var key : Object;
			var i:int=0;
			if(this.datagrid.lstSummaryBar == null)
				return;
			if(this.datagrid.hasSubTotal || this.datagrid.hasTotal)
			{
				for (i = this.datagrid.dataProvider.length -1; i >=0 ; i--) 
				{
					var item : Object = this.datagrid.dataProvider.getItemAt(i);
					if(item && (item[SummaryBarConstant.SUB_TOTAL] == true || item[SummaryBarConstant.TOTAL] == true))
					{
						this.datagrid.dataProvider.removeItemAt(i);
					}
				}
			}
			//remove column which is total
			if(this.datagrid.hasTotalColumn)
			{
				var summaryBar:SummaryBar;
				var listColumns:ArrayCollection;
				if(this.datagrid._isGroupedColumn)
					listColumns=new ArrayCollection(this.datagrid.groupedColumns);
				else
					listColumns=new ArrayCollection(this.datagrid.columns);
				for (key in datagrid.lstSummaryBar) 
				{
					summaryBar = SummaryBar(datagrid.lstSummaryBar[key]);
					if(summaryBar.colMerge == SummaryBarConstant.SUMMARYALL && summaryBar.position == "right")
					{
						for(i=0; i<listColumns.length; i++)
						{
							if(listColumns[i].dataField != null && listColumns[i].dataField == summaryBar.totalColDataField)
							{
								if(this.datagrid.bExternalScroll)
									this.datagrid.totalVisibleColumnWidth -= listColumns[i].width;
								listColumns.removeItemAt(i);
								break;
							}
						}
					}
				}
				if(listColumns.length < this.datagrid.columns.length)
				{
					if(this.datagrid._isGroupedColumn)
					{
						this.datagrid.groupedColumns = listColumns.toArray();
						var updatedCols:Array = new Array(); 
						updatedCols = gridOne.gridoneImpl.convertGroupColumn(listColumns.toArray() , updatedCols)
						this.datagrid.columns = updatedCols;
						for (i=0; i < updatedCols.length; i++)
						{
							this.datagrid.dataFieldIndex[updatedCols[i].dataField]=i;
						}
					}
					else
					{
						this.datagrid.columns=listColumns.toArray();
						for (i=0; i < listColumns.length; i++)
						{
							this.datagrid.dataFieldIndex[listColumns[i].dataField]=i;
						}
					}
				}
			}		
			//update width of datagrid in case Grid is using external scroll bar
			if(this.datagrid.bExternalScroll)
			{
				//horizontal scroll bar
				this.datagrid.width = this.datagrid.totalVisibleColumnWidth;
				//vertical scroll bar
				if(this.datagrid.getLength() <= this.datagrid.rowCount)
					this.datagrid.maxVerticalScrollPosition=0;	
			}
			//reset value and format
			for each(key in datagrid.lstSummaryBar) 
			{
				if(datagrid.lstSummaryBar[key])
				{
					delete datagrid.lstSummaryBar[key];
				}
			}
			this.datagrid.lstSummaryBar = null;
			this.datagrid.lstSummaryBar = new Dictionary();
			this.lstColMergeHasSubTotal = null;
			for each (var col:ExAdvancedDataGridColumn in this.datagrid.columns) 
			{				
				if(col.positionTotalChange != null)
				{
					col.positionTotalChange = null;
					col.positionTotalChange = new Dictionary();
				}
			}
			if(this.datagrid.hasSubTotal)
				this.datagrid.getGroupMergeInfo();
			this.datagrid.hasSubTotal = false;
			this.datagrid.hasTotal = false;
			this.datagrid.hasTotalColumn = false;
			this.datagrid.invalidateList();
		}
		
		/*************************************************************
		 * set summary bar text for total or sub total
		 * @param strSummaryBarKey String
		 * @param strText String
		 * @param isExistTotal Boolean
		 * @param isExistSubTotal Boolean
		 * @author Duong Pham
		 * ***********************************************************/
		public function setSummaryBarText(strSummaryBarKey:String, strText:String,summaryBarType:String):void
		{
			var summaryBar : SummaryBar = this.datagrid.lstSummaryBar[strSummaryBarKey] as SummaryBar;
			//update summary bar
			summaryBar.strText = strText;
			var i:int;
			var item : Object;
			if (summaryBarType == "total" || summaryBarType == "subtotal")
			{
				for (i = this.datagrid.dataProvider.length -1; i >=0 ; i--) 
				{
					item =  this.datagrid.dataProvider[i];
					if((item[SummaryBarConstant.TOTAL] != null || item[SummaryBarConstant.SUB_TOTAL] != null) && item[SummaryBarConstant.SUMMARY_BAR_KEY] == strSummaryBarKey)
					{
						//update item
						item[summaryBar.colMerge] = strText;
						if(summaryBarType == "total")
							break;
					}
				}
			}
			else
			{
				for (i = 0; i < this.datagrid.dataProvider.length; i++) 
				{
					item = this.datagrid.dataProvider[i];
					item[summaryBar.totalColDataField] = strText;
				}
			}
			this.datagrid.invalidateList();
		}
		
		/*************************************************************
		 * set summary bar color
		 * @param strSummaryBarKey String
		 * @param fgColor String
		 * @param bgColor String
		 * @param isTotal Boolean
		 * @author Duong Pham
		 * ***********************************************************/
		public function setSummaryBarColor(strSummaryBarKey:String, fgColor:String, bgColor:String, isTotal : Boolean):void
		{
			this.datagrid.setRowSummaryBarStyle(strSummaryBarKey,"backgroundColor",bgColor);
			this.datagrid.setRowSummaryBarStyle(strSummaryBarKey,"color",fgColor);
		}

		private function setFontSummary(col : ExAdvancedDataGridColumn,strSummaryBarKey : String,fontFamily:String,fontSize : String,fontWeight : String,fontStyle: String,fontULine: String,fontCLine: Boolean,isTotal : Boolean):void
		{
			var valObj:Object;
			if(col)
			{
				//save font style in _cellDict of column
				this.datagrid.setCellSummaryBarStyle(strSummaryBarKey,col.dataField,"fontFamily",fontFamily);
				this.datagrid.setCellSummaryBarStyle(strSummaryBarKey,col.dataField,"fontSize",fontSize);
				this.datagrid.setCellSummaryBarStyle(strSummaryBarKey,col.dataField,"fontWeight",fontWeight);
				this.datagrid.setCellSummaryBarStyle(strSummaryBarKey,col.dataField,"fontStyle",fontStyle);
				this.datagrid.setCellSummaryBarStyle(strSummaryBarKey,col.dataField,"textDecoration",fontULine);
				if(col.summaryBarStyle == null)
				{
					col.summaryBarStyle  = new Dictionary();
					col.summaryBarStyle[strSummaryBarKey] = new SummaryBarStyle();
				}
				else if (col.summaryBarStyle != null && col.summaryBarStyle[strSummaryBarKey] ==null)
				{
					col.summaryBarStyle[strSummaryBarKey] = new SummaryBarStyle();
				}
				if(isTotal)
					SummaryBarStyle(col.summaryBarStyle[strSummaryBarKey]).totalFontCLine = fontCLine;
				else
					SummaryBarStyle(col.summaryBarStyle[strSummaryBarKey]).subTotalFontCLine = fontCLine;
			}
			else
			{
				//save font style in _rowStyleDict
				this.datagrid.setRowSummaryBarStyle(strSummaryBarKey,"fontFamily",fontFamily);
				this.datagrid.setRowSummaryBarStyle(strSummaryBarKey,"fontSize",fontSize);
				this.datagrid.setRowSummaryBarStyle(strSummaryBarKey,"fontWeight",fontWeight);
				this.datagrid.setRowSummaryBarStyle(strSummaryBarKey,"fontStyle",fontStyle);
				this.datagrid.setRowSummaryBarStyle(strSummaryBarKey,"textDecoration",fontULine);
				// save font center line in dictionary of column
				for each (var column : ExAdvancedDataGridColumn in datagrid.columns) 
				{
					if(column.summaryBarStyle == null)
					{
						column.summaryBarStyle  = new Dictionary();
						column.summaryBarStyle[strSummaryBarKey] = new SummaryBarStyle();
					}
					else if (column.summaryBarStyle != null && column.summaryBarStyle[strSummaryBarKey] ==null)
					{
						column.summaryBarStyle[strSummaryBarKey] = new SummaryBarStyle();
					}
					if(isTotal)
						SummaryBarStyle(column.summaryBarStyle[strSummaryBarKey]).totalFontCLine = fontCLine;
					else
						SummaryBarStyle(column.summaryBarStyle[strSummaryBarKey]).subTotalFontCLine = fontCLine;
				}
			}
		}
		
		/*************************************************************
		 * set summary bar font
		 * @param strSummaryBarKey String 
		 * @param strName String
		 * @param nSize int 
		 * @param bBold Boolean
		 * @param bItalic Boolean
		 * @param bUnderLine Boolean
		 * @param bCenterLine Boolean
		 * @param columnKey Strinng
		 * @param isTotal Boolean
		 * author: Hoang Pham
		 * ***********************************************************/
		public function setSummaryBarFont(strSummaryBarKey:String, fontFamily:String,fontSize : String,fontWeight : String,fontStyle: String,fontULine: String,fontCLine: Boolean ,isTotal:Boolean, columnKey : String= null):void
		{
			if(columnKey !=null && StringUtil.trim(columnKey).length>0)
			{
				var colStyle : ExAdvancedDataGridColumn = datagrid.columns[datagrid.dataFieldIndex[columnKey]] as ExAdvancedDataGridColumn;
				setFontSummary(colStyle ,strSummaryBarKey ,fontFamily,fontSize ,fontWeight ,fontStyle,fontULine, fontCLine, isTotal);
			}
			else
			{
				setFontSummary(null ,strSummaryBarKey ,fontFamily,fontSize ,fontWeight ,fontStyle,fontULine, fontCLine, isTotal);
			}
		}
		
		/*************************************************************
		 * set summary bar format
		 * @param strSummaryBarKey String
		 * @param strColumnKey String
		 * @param strFormat String
		 * @author Duong Pham
		 * ***********************************************************/
		public function setSummaryBarFormat(strSummaryBarKey:String, strColumnKey:String, strFormat:String):void
		{
			var col : ExAdvancedDataGridColumn = datagrid.columns[datagrid.dataFieldIndex[strColumnKey]] as ExAdvancedDataGridColumn;
			if(col.formatType == null)
				col.formatType = new Dictionary();
			col.formatType[strSummaryBarKey] = strFormat;
			datagrid.invalidateList();
		}
				
		/*************************************************************
		 * set summary bar value
		 * @param strSummaryBarKey String
		 * @param strColumnKey String
		 * @param nMergeIndex Number
		 * @param strValue String
		 * @param isTotal Boolean
		 * @param isSubTotal Boolean
		 * author: Hoang Pham
		 * ***********************************************************/
		public function setSummaryBarValue(strSummaryBarKey:String, strColumnKey:String, nMergeIndex:Number, strValue:String,summaryBarType:String):void
		{
			var count : int = -1;
			var positionTotalChange : Dictionary;
			var row :Object;
			if(summaryBarType == "total")
			{
				//in this case , nMergeIndex will be ignore
				for each (row in this.datagrid.dataProvider) 
				{
					if(row[SummaryBarConstant.TOTAL] != null)
					{
						if(row[SummaryBarConstant.SUMMARY_BAR_KEY] == strSummaryBarKey)
						{
							row[strColumnKey] = strValue;
							positionTotalChange = (datagrid.columns[datagrid.dataFieldIndex[strColumnKey]] as ExAdvancedDataGridColumn).positionTotalChange;
							if(positionTotalChange == null)
							{
								positionTotalChange = new Dictionary();
							}
							positionTotalChange [strSummaryBarKey + '_' +strColumnKey + '_' + 0] =  strValue; 
							break;
						}
					}
				}
			}
			else if(summaryBarType == "subtotal")
			{
				for each (row in this.datagrid.dataProvider) 
				{
					if(row[SummaryBarConstant.SUB_TOTAL] != null)
					{
						if(row[SummaryBarConstant.SUMMARY_BAR_KEY] == strSummaryBarKey)
							count++;
						if(count == nMergeIndex)
						{
							row[strColumnKey] = strValue;
							positionTotalChange = (datagrid.columns[datagrid.dataFieldIndex[strColumnKey]] as ExAdvancedDataGridColumn).positionTotalChange;
							if(positionTotalChange == null)
							{
								positionTotalChange = new Dictionary();
							}
							positionTotalChange [strSummaryBarKey + '_' + strColumnKey + '_' + nMergeIndex] =  strValue; 
							break;
						}
					}
				}
			}
			else		//total column
			{
				//in this case , strColumnKey will be ignore
				var summaryBar:SummaryBar = this.datagrid.lstSummaryBar[strSummaryBarKey];
				row = this.datagrid.dataProvider[nMergeIndex];
				row[summaryBar.totalColDataField] = strValue;
				positionTotalChange = (datagrid.columns[datagrid.dataFieldIndex[strColumnKey]] as ExAdvancedDataGridColumn).positionTotalChange;
				if(positionTotalChange == null)
				{
					positionTotalChange = new Dictionary();
				}
				positionTotalChange [strSummaryBarKey + '_' + summaryBar.totalColDataField + '_' + nMergeIndex] =  strValue; 
			}
		}
		
		/*******************************************************6******
		 * set group merge
		 * @author Duong Pham
		 * ***********************************************************/
		public function  resetGroupMerge():void
		{
			for each (var col:ExAdvancedDataGridColumn in this.datagrid.columns)
			{
				if (col.merge)
					col.merge = false;
			}
		}
		
		/*************************************************************
		 * get summary bar function
		 * @param strSummaryBarKey String
		 * @param strColumnKey String
		 * @param nMergeIndex Number
		 * @param bDataFormat Boolean
		 * @author Duong Pham
		 * ***********************************************************/
		public function getSummaryBarValueForSubTotal(strSummaryBarKey:String, strColumnKey:String, nMergeIndex:Number, bDataFormat : Boolean):String
		{
			var index : int;
			var count : int = -1;
			var column : ExAdvancedDataGridColumn;
			var returnValue : String ;
			var item : Object;
			
			for each (var row :Object in this.datagrid.dataProvider) 
			{
				if(row[SummaryBarConstant.SUB_TOTAL] != null)
				{
					if(row[SummaryBarConstant.SUMMARY_BAR_KEY] == strSummaryBarKey)
					{
						count++;
					}
					if(count == nMergeIndex)
					{
						column = gridOne.getColumnByDataField(strColumnKey) as ExAdvancedDataGridColumn; 
						var positionTotalChange : Dictionary = column.positionTotalChange;
						
						if(positionTotalChange[strSummaryBarKey + '_' + strColumnKey+ '_' + nMergeIndex] != null)
						{
							returnValue = positionTotalChange [strSummaryBarKey + '_' + strColumnKey + '_' +nMergeIndex].toString();
						}
						else
						{
							//calculate 
							var customCol : ExAdvancedDataGridColumn = gridOne.getColumnByDataField(row[SummaryBarConstant.SUMMARY_MERGE_COLUMN]) as ExAdvancedDataGridColumn; 
							var func : String = customCol.summaryBar.functionList[strColumnKey].toString();
							if(func == SummaryBarConstant.FUNC_CUSTOM)
							{
								returnValue = '0';
							}
							else
							{
								var currentIndex : int = this.datagrid.dataProvider.getItemIndex(row);
								returnValue = calculateSubTotal(func,currentIndex,strSummaryBarKey,column).toString();
							}
						}
						item = row;
						break;
					}
				}
			}
			if(isNaN(Number(returnValue)))
			{
				return returnValue;
			}
			
			if(bDataFormat)
				returnValue = formatBaseOnPatternTotal(column,Number(returnValue),item);
			return returnValue;
		}
		
		/*************************************************************
		 * get summary bar function
		 * @param strSummaryBarKey String
		 * @param strColumnKey String
		 * @param nMergeIndex Number
		 * @param bDataFormat Boolean
		 * @author Duong Pham
		 * ***********************************************************/
		public function getSummaryBarValueForTotal(strSummaryBarKey:String, strColumnKey:String, nMergeIndex:Number, bDataFormat : Boolean):String
		{			
			var index : int = 0;
			var count : int = -1;
			var column : ExAdvancedDataGridColumn;
			var returnValue : String ;
			var item : Object;
			
			for(var i : int = this.datagrid.dataProvider.length -1 ;i >=0  ;i--)
			{
				var total : Object = this.datagrid.dataProvider[i];
				if(total[SummaryBarConstant.TOTAL] != null)
				{
					if(total[SummaryBarConstant.SUMMARY_BAR_KEY] == strSummaryBarKey)
					{
						column = gridOne.getColumnByDataField(strColumnKey) as ExAdvancedDataGridColumn; 
						if(column.positionTotalChange[strSummaryBarKey + '_' +column.dataField + '_' + index] != null)
						{
							returnValue = column.positionTotalChange [strSummaryBarKey + '_' + strColumnKey + '_' +index].toString();
						}						
						else
						{
							//calculate 
							var colMerge : ExAdvancedDataGridColumn = gridOne.getColumnByDataField(total[SummaryBarConstant.SUMMARY_BAR_KEY]) as ExAdvancedDataGridColumn; 
							var func : String= (this.datagrid.lstSummaryBar[strSummaryBarKey] as SummaryBar).functionList[strColumnKey].toString();
							if(func == SummaryBarConstant.FUNC_CUSTOM)
								returnValue = total[strColumnKey];
							else
							{
								var currentIndex : int = this.datagrid.dataProvider.getItemIndex(total);
								returnValue = calculateTotal(func,strSummaryBarKey,column).toString();
							}
						}
						item = total;
						break;
					}
				}
			}
			if(isNaN(Number(returnValue)))
			{
				return returnValue;
			}
			if(bDataFormat)
				returnValue = formatBaseOnPatternTotal(column,Number(returnValue),item);
			return returnValue;
		}
				
		/*************************************************************
		 * order list of column merge using for subtotal when add another sub total
		 * @param strMergeColumn String
		 * @author Duong Pham
		 * ***********************************************************/
		private function reOrderColMergePos(strMergeColumn : String):void
		{
			if(this.lstColMergeHasSubTotal.length == 0)
				this.lstColMergeHasSubTotal.addItem(strMergeColumn);
			else
			{
				//just for test
				if(this.lstColMergeHasSubTotal.contains(strMergeColumn))
				{
					return;
				}
				//end
				var colMergrIndex : int = this.datagrid.dataFieldIndex[strMergeColumn];
				var hasInput : Boolean =false;
				for (var m:int = 0; m < this.lstColMergeHasSubTotal.length; m++) 
				{
					if(colMergrIndex < this.datagrid.dataFieldIndex[this.lstColMergeHasSubTotal[m]])
					{
						this.lstColMergeHasSubTotal.addItemAt(strMergeColumn,m);
						hasInput= true;
						break;
					}
				}
				if(!hasInput)
					this.lstColMergeHasSubTotal.addItem(strMergeColumn);
			} 
		}
		
		/*************************************************************
		 * create new summary bar
		 * @param strMergeColumn String
		 * @param strText String
		 * @param strColumnList String
		 * @param strFunc String
		 * @param strSummaryBarKey String
		 * @return SummaryBar
		 * @author Duong Pham
		 * ***********************************************************/		
		private function createNewSummaryBar(strMergeColumn : String,strText: String,strColumnList: String,strFunc: String,strSummaryBarKey: String,position:String):SummaryBar
		{
			var summaryBar : SummaryBar = new SummaryBar();
			summaryBar.colMerge = strMergeColumn; 
			summaryBar.strText = strText;
			summaryBar.type = SummaryBarConstant.SUB_TOTAL;
			summaryBar.strColumnList = strColumnList;
			summaryBar.position = position;
			summaryBar.summaryBarKey = strSummaryBarKey;
			summaryBar.strFunction = strFunc.toLowerCase();
			
			//set function
			var colKeyLst : Array = strColumnList.split(',');
			var tempCol:ExAdvancedDataGridColumn;
			for (var v:int = 0; v < colKeyLst.length; v++) 
			{
				tempCol = this.datagrid.columns[this.datagrid.dataFieldIndex[colKeyLst[v]]] as ExAdvancedDataGridColumn;
				tempCol.subToltalColumn=true;
				if(tempCol.type != ColumnType.NUMBER)
				{
					if(strFunc == SummaryBarConstant.FUNC_AVERAGE || strFunc == SummaryBarConstant.FUNC_COUNT || strFunc == SummaryBarConstant.FUNC_SUM)
						strFunc = SummaryBarConstant.FUNC_COUNT;
					else
						strFunc = SummaryBarConstant.FUNC_CUSTOM;
				}
				summaryBar.functionList[colKeyLst[v]] = strFunc;
			}
			return summaryBar;
		}
		
		/*************************************************************
		 * add summary bar
		 * @param columnKey String;
		 * @author Duong Pham
		 * ***********************************************************/
		public function addSummaryBar(strSummaryBarKey:String, strText:String, strMergeColumn:String, strFunc:String, strColumnList:String,position:String="bottom"):void
		{
			//diable sort
			if(!this.datagrid.hasTotal && !this.datagrid.hasSubTotal)
			{
				for each (var col:ExAdvancedDataGridColumn in this.datagrid.columns) 
				{
					col.sortable = false;
				}
			}
			//resetGroupMerge();
			if(strMergeColumn.toLowerCase() == SummaryBarConstant.SUMMARYALL)
			{
				insertSummaryAll(strMergeColumn,strText,strColumnList, strFunc, strSummaryBarKey,position);
			}
			else
			{
				resetSummaryBar();
				var startMegreIndex : int ;
				var endMergeIndex : int;
				
				if(this.lstColMergeHasSubTotal == null)
					this.lstColMergeHasSubTotal = new ArrayCollection();
				
				var dataprovider : ArrayCollection = this.datagrid.dataProvider as ArrayCollection;
				var total : Number  = 0;
				var bkTotal : Object;
				/************************sub total from here*********************************/
				
				//save summary bar info
				var summaryBar : SummaryBar;
				//add to lst
				if(this.datagrid.lstSummaryBar == null)
					this.datagrid.lstSummaryBar = new Dictionary();
				
				if(this.datagrid.lstSummaryBar && this.datagrid.lstSummaryBar[strSummaryBarKey] == null)
				{
					summaryBar = createNewSummaryBar(strMergeColumn,strText,strColumnList,strFunc,strSummaryBarKey,position);
					this.datagrid.lstSummaryBar[strSummaryBarKey] = summaryBar;
				}
				else
					summaryBar = this.datagrid.lstSummaryBar [strSummaryBarKey];
				
				
				var mergeColumn:ExAdvancedDataGridColumn = gridOne.getColumnByDataField(strMergeColumn) as ExAdvancedDataGridColumn;
				mergeColumn.summaryBar = summaryBar;
				mergeColumn.strSummaryBarKey = strSummaryBarKey;
				
				
				//order merged column into array lstColMergeHasSubTotal to create sub total 
				reOrderColMergePos(strMergeColumn);
				
				var strMergeColumnHasSubTotal : String = this.lstColMergeHasSubTotal.getItemAt(0).toString();
				var tempCol:ExAdvancedDataGridColumn;
				if(strMergeColumnHasSubTotal == strMergeColumn)
					tempCol = mergeColumn;
				else
					tempCol = gridOne.getColumnByDataField(strMergeColumnHasSubTotal) as ExAdvancedDataGridColumn;
				var previous : Object;
				var item : Object;
				//var count : int = 1;
				startMegreIndex = 0; 
				var newItem : Object;
				for (var i:int = 0; i <= dataprovider.length; i++) 
				{
					if(previous == null) //first tiem
					{
						item = dataprovider.getItemAt(i);
						if(item[SummaryBarConstant.SUB_TOTAL] == null)
							previous = item;
					}
					else
					{
						if(i == dataprovider.length)
						{
							//insert value
							if(previous[SummaryBarConstant.SUB_TOTAL] == null)
							{
								newItem = new Object();
								newItem[SummaryBarConstant.SUB_TOTAL] =true;
								newItem[SummaryBarConstant.SUMMARY_BAR_KEY] = tempCol.summaryBar.summaryBarKey;
								newItem[SummaryBarConstant.SUMMARY_FUNCTION_NAME] = tempCol.summaryBar.strFunction;
								newItem[SummaryBarConstant.SUMMARY_MERGE_COLUMN] = strMergeColumnHasSubTotal;
								newItem[SummaryBarConstant.SUMMARY_COLUMN_LIST] = strColumnList;
								newItem[strMergeColumnHasSubTotal] = tempCol.summaryBar.strText;
								
								fillDataForSubTotal(this.datagrid.lstMergeColumn,newItem,previous,strMergeColumnHasSubTotal);
								
								dataprovider.addItemAt(newItem,i);
								
								endMergeIndex = i;
								//insert another sub total for the next merged column in lstColMergeHasSubTotal
								if(this.lstColMergeHasSubTotal.length>1)
									insertOtherSubTotal(this.lstColMergeHasSubTotal,0,startMegreIndex,newItem);
							}
							//add final
							break;
						} 
						item = dataprovider.getItemAt(i);
						if(item[SummaryBarConstant.SUB_TOTAL] == null)
						{
							if(previous[strMergeColumnHasSubTotal] != item[strMergeColumnHasSubTotal])
							{
								newItem = new Object();
								newItem[SummaryBarConstant.SUB_TOTAL] =true;
								newItem[SummaryBarConstant.SUMMARY_BAR_KEY] = tempCol.summaryBar.summaryBarKey;
								newItem[SummaryBarConstant.SUMMARY_FUNCTION_NAME] = tempCol.summaryBar.strFunction;
								newItem[SummaryBarConstant.SUMMARY_MERGE_COLUMN] = strMergeColumnHasSubTotal;
								newItem[SummaryBarConstant.SUMMARY_COLUMN_LIST] = strColumnList;
								newItem[strMergeColumnHasSubTotal] = tempCol.summaryBar.strText;
								
								fillDataForSubTotal(this.datagrid.lstMergeColumn,newItem,previous,strMergeColumnHasSubTotal);
								
								dataprovider.addItemAt(newItem,i);
								bkTotal = newItem;
								endMergeIndex = i;
								//insert another sub total for the next merged column in lstColMergeHasSubTotal
								if(this.lstColMergeHasSubTotal.length>1)
									insertOtherSubTotal(this.lstColMergeHasSubTotal,0,startMegreIndex,bkTotal);
								i = dataprovider.getItemIndex(bkTotal) + 1;
								startMegreIndex =i;
							}
						}
						previous = item;
					}
				}
				this.datagrid.hasSubTotal = true; 
				var summaryBarAdd : SummaryBar;
				if(this.datagrid.hasTotal)
				{
					for (var key:Object in this.datagrid.lstSummaryBar)
					{
						summaryBarAdd = this.datagrid.lstSummaryBar [key] as SummaryBar;
						if(summaryBarAdd.colMerge == SummaryBarConstant.SUMMARYALL)
							insertSummaryAll(SummaryBarConstant.SUMMARYALL,summaryBarAdd.strText,summaryBarAdd.strColumnList, summaryBarAdd.strFunction, summaryBarAdd.summaryBarKey,position);
					} 
				}
			}
		}
	
		/*************************************************************
		 * build list column merge
		 * @param gridOne : GridOne
		 * author: Duong Pham
		 * ***********************************************************/
		public function buildListColMerge():void
		{
			//build list column merge
			if(!this.datagrid.hasSubTotal )
			{
				//build list column merge
				for each (var col:ExAdvancedDataGridColumn in this.datagrid.columns)
				{
					if (col.merge)
					{
						if(this.datagrid.lstMergeColumn == null)
							this.datagrid.lstMergeColumn = new ArrayCollection();
						if(this.datagrid.lstMergeColumn.getItemIndex(col.dataField)<0)
							this.datagrid.lstMergeColumn.addItem(col.dataField);
					}
				}	
			}
			
		}
 		
		/*************************************************************
		 * check column is merged or not
		 * @author Duong Pham
		 * ***********************************************************/
		public function isValidColMerge(checkCol : String,lstMergeColumn : ArrayCollection):Boolean
		{
			var rs : Boolean = false;
			for each (var colMerge : String in lstMergeColumn) 
			{
				if(colMerge == checkCol)
				{
					rs = true;
					break;
				}
			}
			return rs;
		}
		
		/*************************************************************
		 * format sub total and total base on format column or per summary bar
		 * @param column ExAdvancedDataGridColumn
		 * @param value Number
		 * @param item Object
		 * @author Duong Pham
		 * ***********************************************************/
		public function formatBaseOnPatternTotal(column : ExAdvancedDataGridColumn, value : Number, item : Object):String
		{
			if(item[SummaryBarConstant.SUMMARY_BAR_KEY] != null)
			{				
				var rs : String ='';
				var pattern : String = '';				
				if(!isExistSummaryKey(item[SummaryBarConstant.SUMMARY_BAR_KEY],column.formatType))
					pattern = column.formatString;
				else
					pattern = column.formatType[item[SummaryBarConstant.SUMMARY_BAR_KEY]];				
				if(pattern == '')
					return setDefaultNumberFormat(column, value); 
				if(pattern.indexOf(':') > 0)
				{
					var data : Array = pattern.split(':');
					return (  value + ':' + data[1]);
				}
				
				var formatter : CurrencyFormatter = new CurrencyFormatter ();
				var expression:RegExp=/[#0][#0,.]*[0#]/g;
				var currencyArr:Array=pattern.toString().split(expression);
				var strCurrencyBefore : String = currencyArr[0];
				var strCurrencyAfter : String =currencyArr[1];
				
				var strFormat:Array = pattern.toString().match(expression);
				var arrPrecision:Array=strFormat[0].split(".")
				
				var precision : int =0;
				if (arrPrecision.length == 2 && arrPrecision[1].toString() != "")
				{
					precision=arrPrecision[1].toString().length;
				}
				var numberFormatter : NumberFormatter = new NumberFormatter();
				numberFormatter.thousandsSeparatorTo = ',';
				numberFormatter.decimalSeparatorTo = '.';
				numberFormatter.precision = precision;
				
				var symbolNumberType : String ='';
				if(precision > 0)
				{
					symbolNumberType = arrPrecision[1].toString().charAt(0);
					value = Number(value.toFixed(precision));
				}
				
				if(symbolNumberType == '#')
				{
					rs  = numberFormatter.format(value);
					rs = removeZeroNumber(rs);
					rs = strCurrencyBefore + rs + strCurrencyAfter;
					return rs;
				}
				else
				{
					rs = numberFormatter.format(value);
					rs = strCurrencyBefore + rs + strCurrencyAfter;
					return rs;
				}
			}
			else
				return setDefaultNumberFormat(column, value); 
		}
		
		/*************************************************************
		 * insert other sub total than first sub total
		 * @param lstColMergeHasSubTotal ArrayCollection
		 * @param currentMergeIndex int
		 * @param startMergeIndex int
		 * @param bkObject Object
		 * @author Duong Pham
		 * ***********************************************************/
		public function insertOtherSubTotal(lstColMergeHasSubTotal : ArrayCollection,currentMergeIndex : int, startMergeIndex : int,bkObject : Object):void
		{
			var dataprovider : ArrayCollection =  datagrid.dataProvider as ArrayCollection ;
			var previous : Object;
			var summaryBarKey : String;
			var beginIndex : int = startMergeIndex; 
			var endIndex : int = 0;
			var bkTotal : Object;
			var n:int = currentMergeIndex +1;
			var column:ExAdvancedDataGridColumn;
			var endMergeIndex : int = dataprovider.getItemIndex(bkObject);
//			(this.datagrid.columns[this.datagrid.dataFieldIndex[lstColMergeHasSubTotal[n]]] as ExAdvancedDataGridColumn).labelSubTotal = true;
			for (var i:int = startMergeIndex; i <= endMergeIndex; i++) 
			{
				var newItem : Object = new Object ();
				var item : Object = dataprovider.getItemAt(i);
				if(previous == null)
					previous = item;
				else
				{
					if(item[SummaryBarConstant.SUB_TOTAL] == null)
					{
						if(previous[lstColMergeHasSubTotal[n]] != item[lstColMergeHasSubTotal[n]])
						{
							//fill data for new row, to keep merge column correct
							fillDataForSubTotal(datagrid.lstMergeColumn,newItem,previous,lstColMergeHasSubTotal[n]);
							
							column = (datagrid.columns[datagrid.dataFieldIndex[lstColMergeHasSubTotal[n]]] as ExAdvancedDataGridColumn);
							//set new value for new item
							newItem[SummaryBarConstant.SUB_TOTAL] = true;
							newItem[SummaryBarConstant.SUMMARY_BAR_KEY]= column.summaryBar.summaryBarKey; 
							newItem[lstColMergeHasSubTotal[n]] = column.summaryBar.strText;;
							newItem[SummaryBarConstant.SUMMARY_FUNCTION_NAME] = column.summaryBar.strFunction;
							newItem[SummaryBarConstant.SUMMARY_MERGE_COLUMN] = lstColMergeHasSubTotal[n];
							newItem[SummaryBarConstant.SUMMARY_COLUMN_LIST] = column.summaryBar.strColumnList;
							dataprovider.addItemAt(newItem,i);

							var nextItem : Object = dataprovider.getItemAt(i+1);
							if(nextItem[SummaryBarConstant.SUB_TOTAL]  != null)
								nextItem[lstColMergeHasSubTotal[n]] = '';
							
							bkTotal = newItem;
							endIndex = i;
							if(lstColMergeHasSubTotal.length > (n + 1))
								insertOtherSubTotal(lstColMergeHasSubTotal,n,beginIndex,bkTotal);
							i = dataprovider.getItemIndex(bkTotal) + 1;
							beginIndex = i;
							endMergeIndex = dataprovider.getItemIndex(bkObject);
						}
					}
					else
					{
						//fill data for new row, to keep merge column correct // fixed merge for multi level sub total
						fillDataForSubTotal(datagrid.lstMergeColumn,newItem,previous,lstColMergeHasSubTotal[n]);
						
						column = (datagrid.columns[datagrid.dataFieldIndex[lstColMergeHasSubTotal[n]]] as ExAdvancedDataGridColumn);
						//set new value for new item
						newItem[lstColMergeHasSubTotal[n]] = column.summaryBar.strText;
						newItem[SummaryBarConstant.SUB_TOTAL] = true;
						newItem[SummaryBarConstant.SUMMARY_BAR_KEY]= column.summaryBar.summaryBarKey;
						newItem[SummaryBarConstant.SUMMARY_FUNCTION_NAME] = column.summaryBar.strFunction;
						newItem[SummaryBarConstant.SUMMARY_MERGE_COLUMN] = lstColMergeHasSubTotal[n];
						newItem[SummaryBarConstant.SUMMARY_COLUMN_LIST] = column.summaryBar.strColumnList;
						dataprovider.addItemAt(newItem,i);
						
						var nextRow : Object = dataprovider.getItemAt(i+1);
						if(nextRow[SummaryBarConstant.SUB_TOTAL]  != null)
							nextRow[lstColMergeHasSubTotal[n]] = '';
						
						bkTotal = newItem;
						// check if has more colmerge that using for subtotal, if yes system continute to insert other subtotal
						if(lstColMergeHasSubTotal.length > (n + 1))
							insertOtherSubTotal(lstColMergeHasSubTotal,n,beginIndex,bkTotal);
						break;
					}
					previous = item;
				}				
			}
		}
		
		/*************************************************************
		 * insert summary all 
		 * @param strMergeColumn String
		 * @param strText String
		 * @param strColumnList String
		 * @param strFunc String
		 * @param strSummaryBarKey String
		 * author: Duong Pham
		 * ***********************************************************/
		public function insertSummaryAll(strMergeColumn : String,strText : String,strColumnList : String, strFunc : String, strSummaryBarKey: String,position:String="bottom"):void
		{
			var summaryBar : SummaryBar;
			//add to lst
			if(this.datagrid.lstSummaryBar == null)
				this.datagrid.lstSummaryBar = new Dictionary();
			if(this.datagrid.lstSummaryBar && this.datagrid.lstSummaryBar[strSummaryBarKey] == null)
			{
				summaryBar = new SummaryBar();
				summaryBar.colMerge = strMergeColumn; 
				summaryBar.strText = strText;
				summaryBar.strFunction = strFunc;
				summaryBar.type = SummaryBarConstant.TOTAL;
				summaryBar.strColumnList = strColumnList;
				summaryBar.summaryBarKey = strSummaryBarKey;
				summaryBar.position = position;
				this.datagrid.lstSummaryBar[strSummaryBarKey] = summaryBar;
			}
			else
				summaryBar = this.datagrid.lstSummaryBar [strSummaryBarKey];
			
			//end add to lst
			
			if(position == "top" || position == "bottom")
			{
				this.datagrid.hasTotal = true;
				
				//get the first visible column to set text
				var column:ExAdvancedDataGridColumn;
				for each (column in this.datagrid.columns)
				{
					if(column.visible)
						break;
				}
				
				var newItemAll : Object = new Object();
				newItemAll[SummaryBarConstant.TOTAL] =true;
				newItemAll[SummaryBarConstant.SUMMARY_BAR_KEY] = strSummaryBarKey;
				newItemAll[SummaryBarConstant.SUMMARY_FUNCTION_NAME] = strFunc;
				newItemAll[SummaryBarConstant.SUMMARY_MERGE_COLUMN] = column.dataField;
				newItemAll[SummaryBarConstant.SUMMARY_COLUMN_LIST] = strColumnList;
				
				column = null;
				
				//set function
				var colKeyLst : Array = strColumnList.split(',');
				for (var v:int = 0; v < colKeyLst.length; v++) 
				{
					 
					column = this.datagrid.columns[this.datagrid.dataFieldIndex[colKeyLst[v]]];
					if(column.type == ColumnType.NUMBER)
						summaryBar.functionList[colKeyLst[v]] = strFunc;
					else
						summaryBar.functionList[colKeyLst[v]] = SummaryBarConstant.FUNC_COUNT;
					column.totalColumn = true;
				}
				if(position == "top")
				{
					var jj:int = 0;
					var item:Object;
					while(jj < this.datagrid.getLength())
					{
						item = this.datagrid.getItemAt(jj);
						if(item && !item.hasOwnProperty(SummaryBarConstant.TOTAL))
						{
							(this.datagrid.dataProvider as ArrayCollection).addItemAt(newItemAll,jj);
							break;
						}
						jj ++;
					}
				}
				else
					(this.datagrid.dataProvider as ArrayCollection).addItem(newItemAll);
			}
			else if(position == "right")
			{
				this.datagrid.hasTotalColumn = true;
				var insertedColumn:ExAdvancedDataGridColumn = new ExAdvancedDataGridColumn();
				insertedColumn.dataField = summaryBar.totalColDataField =  Global.TOTAL_DATAFIELD + index;
				insertedColumn.headerText = summaryBar.strText;
				insertedColumn.width= 100;
				insertedColumn.type=ColumnType.TOTAL;
				this.gridOne.setItemRenderer(insertedColumn,insertedColumn.type,false);
				insertedColumn.summaryBar = summaryBar;		//save information summary bar in column
				var listColumns:ArrayCollection;
				if(this.datagrid._isGroupedColumn)
					listColumns= new ArrayCollection(this.datagrid.groupedColumns);
				else
					listColumns= new ArrayCollection(this.datagrid.columns);
				listColumns.addItem(insertedColumn);
				index ++;		//increase index of dataField column total
				
				//add total column into datagrid.columns
				if(this.datagrid._isGroupedColumn)
				{
					this.datagrid.groupedColumns = listColumns.toArray();
					var updatedCols:Array = new Array(); 
					updatedCols = gridOne.gridoneImpl.convertGroupColumn(listColumns.toArray() , updatedCols)
					this.datagrid.columns = updatedCols;
					for (i=0; i < updatedCols.length; i++)
					{
						this.datagrid.dataFieldIndex[updatedCols[i].dataField]=i;
					}	
				}
				else
				{
					this.datagrid.columns = listColumns.toArray();
					//update dataFieldIndex
					this.datagrid.dataFieldIndex = new Object();
					for (var i:int=0; i < listColumns.length; i++)
					{
						this.datagrid.dataFieldIndex[listColumns[i].dataField]=i;
					}
				}
				//If external scroll is used, update datagrid's width
				if(this.datagrid.bExternalScroll)
				{
					this.datagrid.width = this.datagrid.totalVisibleColumnWidth = this.datagrid.totalVisibleColumnWidth + insertedColumn.width;
				}
			}
		}
		
		/*************************************************************
		 * calculate total value
		 * @param strFunc String
		 * @param currentSummaryBarKey String
		 * @param column ExAdvancedDataGridColumn
		 * @return Number
		 * @author: Duong Pham
		 * ***********************************************************/
		public function calculateTotal(strFunc : String,currentSummaryBarKey : String,column : ExAdvancedDataGridColumn): Number
		{
			var value : Number = 0;
			var count :int = 0;
			if(strFunc == SummaryBarConstant.FUNC_SUM ||strFunc == SummaryBarConstant.FUNC_AVERAGE || strFunc == SummaryBarConstant.FUNC_COUNT) 
			{
				for each (var obj:Object in this.datagrid.dataProvider) 
				{
					if(obj[SummaryBarConstant.SUB_TOTAL] == null && obj[SummaryBarConstant.TOTAL] == null)
					{
						if(strFunc == SummaryBarConstant.FUNC_AVERAGE || strFunc == SummaryBarConstant.FUNC_COUNT )
							count++;
						if(strFunc != SummaryBarConstant.FUNC_COUNT)
							value = value + Number(obj[column.dataField]);
					}
				}
				if(strFunc == SummaryBarConstant.FUNC_COUNT)
					value = count;
				else if (strFunc == SummaryBarConstant.FUNC_AVERAGE)
					value = value/count;
			}
				
			else if (strFunc ==  SummaryBarConstant.FUNC_CUSTOM) // not calculating 
			{
				value= 0;
			}
			return value;
		}		
		
		/*************************************************************
		 * calculate total value
		 * @param strFunc String
		 * @param currentIndex int
		 * @param currentSummaryBarKey String
		 * @param column ExAdvancedDataGridColumn
		 * @return Number
		 * author: Duong Pham
		 * ***********************************************************/
		public function calculateSubTotal(strFunc : String, currentIndex : int, currentSummaryBarKey : String,column : ExAdvancedDataGridColumn): Number
		{
			var value : Number = 0;
			var count :int = 0;
			
			if(strFunc == SummaryBarConstant.FUNC_SUM ||strFunc == SummaryBarConstant.FUNC_AVERAGE || strFunc == SummaryBarConstant.FUNC_COUNT) 
			{
				for (var j:int = currentIndex-1; j >= 0; j--) 
				{
					var obj : Object = this.datagrid.dataProvider.getItemAt(j);
					if(obj[SummaryBarConstant.SUB_TOTAL] == null && obj[SummaryBarConstant.TOTAL] == null)
					{
						if(strFunc == SummaryBarConstant.FUNC_AVERAGE || strFunc == SummaryBarConstant.FUNC_COUNT )
							count++;
						if(strFunc != SummaryBarConstant.FUNC_COUNT)
							value = value + Number(obj[column.dataField])
					}
					else
					{
						if(obj[SummaryBarConstant.SUMMARY_BAR_KEY] == currentSummaryBarKey)
						{
							break;
						}
					}
				}
				if(strFunc == SummaryBarConstant.FUNC_COUNT)
					value = count;
				else if (strFunc == SummaryBarConstant.FUNC_AVERAGE)
					value = value/count;
			}
			else if (strFunc ==  SummaryBarConstant.FUNC_CUSTOM) // not calculating 
			{
				value= 0;
			}
			return value;
		}		
		
		/*************************************************************
		 * recreate summary bar
		 * @author: Duong Pham
		 * ***********************************************************/
		public function reCreateSummaryBar(isReset:Boolean=false):void
		{
			var summaryBar : SummaryBar;
			if(!isReset)
			{
				resetSummaryBar();
			}
			if(datagrid.hasSubTotal)
			{
				//get first colmerge
				for each (var col:ExAdvancedDataGridColumn in datagrid.columns)
				{
					//if (col.merge && col.subToltalColumn)
					if (col.merge)
					{
						summaryBar = col.summaryBar;
						break;
					}
				}	
			}
			else if(datagrid.hasTotal)
			{
				for (var key:Object in this.datagrid.lstSummaryBar)
				{
					if(this.datagrid.lstSummaryBar[key] && datagrid.lstSummaryBar[key].colMerge == SummaryBarConstant.SUMMARYALL)
					{
						summaryBar = this.datagrid.lstSummaryBar [key];
						break;
					}
				} 
			}
			addSummaryBar(summaryBar.summaryBarKey, summaryBar.strText,summaryBar.colMerge, summaryBar.strFunction, summaryBar.strColumnList,summaryBar.position);
		}
		
		/*************************************************************
		 * remove all summary bars in data provider
		 * author: Duong Pham
		 * ***********************************************************/
		public function resetSummaryBar():void
		{
			//remove rows total and sub total
			var i:int=0;
			if(this.datagrid.hasTotal || this.datagrid.hasSubTotal)
			{
				for (i = this.datagrid.dataProvider.length -1 ; i >=0  ; i--) 
				{
					var item : Object = this.datagrid.dataProvider[i];
					if(item[SummaryBarConstant.SUB_TOTAL]!= null || item[SummaryBarConstant.TOTAL]!= null)
					{
						this.datagrid.dataProvider.removeItemAt(i);
					}
				}
			}
		}
		
		/*************************************************************
		 * get current index of sub total
		 * @param summaryBarKey
		 * @param currentIndex int
		 * @param dp ArrayCollection
		 * author: Duong Pham
		 * ***********************************************************/
		public function getCurrentIndexofTotal( summaryBarKey : String, currentIndex : int): int
		{
			var count : int = 0;
			for (var i:int = currentIndex - 1; i >=0; i--) 
			{
				var row : Object = this.datagrid.dataProvider.getItemAt(i);
				if(row[SummaryBarConstant.SUB_TOTAL] != null)
				{
					if(row[SummaryBarConstant.SUMMARY_BAR_KEY] == summaryBarKey)
						count++;
				}
			}
			return count;
		}
		
		/*************************************************************
		 * remove summary bar value to be set by setSummaryBarValue when changing new function
		 * @param summaryBarKey String
		 * @param positionTotalChange Dictionary
		 * author: Hoang Pham
		 * ***********************************************************/
		public function removeCustomSummaryBarValue(summaryBarKey : String,positionTotalChange : Dictionary):void
		{
			var keyArr : Array = DictionaryUtil.getKeys(positionTotalChange);
			var keyItem : Array;
			for (var i:int = 0; i < keyArr.length; i++) 
			{
				keyItem  = keyArr[i].split('_');
				if(keyItem[0] == summaryBarKey)
					delete positionTotalChange[keyArr[i]];
			}	
		}
		
		/*************************************************************
		 * clear sort		
		 * author Duong Pham
		 * ***********************************************************/
		public function clearSort():void
		{
			datagrid.sortableColumns = false;
			if(datagrid.dataProvider && datagrid.dataProvider.length > 0)
			{
				(datagrid.dataProvider as ArrayCollection).sort = null;
				(datagrid._bkDP as ArrayCollection).sort = null;			
				for each (var col : ExAdvancedDataGridColumn in datagrid.columns) 
				{
					col.sortCompareFunction = null;
				}
				(datagrid.dataProvider as ArrayCollection).refresh();
				(datagrid._bkDP as ArrayCollection).refresh();
			}
		}
		
		/*************************************************************
		 * reset sort to default sort of datagrid		
		 * author: Duong Pham
		 * ***********************************************************/
		public function resetSort():void
		{
			datagrid.sortableColumns = true;
			(datagrid.dataProvider as ArrayCollection).refresh();
			(datagrid._bkDP as ArrayCollection).refresh();
		}
				
		/*************************************************************
		 * fill data for merge column when has subtotal to ensurce merge in group of data
		 * @param lstMergeColumn ArrayCollection
		 * @param newItem Object
		 * @param previous Object
		 * @author Hoang Pham
		 * ***********************************************************/
		private function fillDataForSubTotal(lstMergeColumn : ArrayCollection, newItem : Object, previous : Object, colMerge:String):void
		{
			for (var j:int = 0; j < lstMergeColumn.length; j++) 
			{
				if(this.datagrid.lstMergeColumn[j] == colMerge)
					break;
				else
					newItem[this.datagrid.lstMergeColumn[j]] = previous[this.datagrid.lstMergeColumn[j]];
			}
		}
		
		/*************************************************************
		 * check if a column is sub total column
		 * @param summaryBar SummaryBar
		 * @param col ExAdvancedDataGridColumn
		 * @return Boolean
		 * @author Duong Pham
		 * ***********************************************************/
		public function isSubTotalCol(summaryBar : SummaryBar, col : ExAdvancedDataGridColumn): Boolean
		{
			var rs : Boolean = false;
			if(summaryBar != null && summaryBar.functionList != null)
			{
				var keyArr : Array = DictionaryUtil.getKeys(summaryBar.functionList);
				var keyItem : Array;
				for (var i:int = 0; i < keyArr.length; i++) 
				{
					if((keyArr[i] == col.dataField) && col.subToltalColumn)
					{
						rs  = true;
						break;
					}
				}	
			}
			return rs;
		}
		
		/*************************************************************
		 * check if a column is total column
		 * @param summaryBar SummaryBar
		 * @param col ExAdvancedDataGridColumn
		 * @return Boolean
		 * @author: Duong Pham
		 * ***********************************************************/
		public function isTotalCol(summaryBar : SummaryBar, col : ExAdvancedDataGridColumn): Boolean
		{
			var rs : Boolean = false;
			if(summaryBar != null && summaryBar.functionList != null)
			{
				var keyArr : Array = DictionaryUtil.getKeys(summaryBar.functionList);
				var keyItem : Array;
				for (var i:int = 0; i < keyArr.length; i++) 
				{
					if((keyArr[i] == col.dataField) && col.totalColumn)
					{
						rs  = true;
						break;
					}
				}	
			}
			return rs;
		}
		
		/*************************************************************
		 * remove old summary bar when add new summarybar, has the same merge column, is added 
		 * @param strMergeColumn String
		 * @return Boolean
		 * author Duong Pham
		 * ***********************************************************/
		public function removeOldSummarBar(strMergeColumn : String) : void
		{
			if(datagrid.lstSummaryBar)
			{
				for (var key : Object in datagrid.lstSummaryBar) {
					if((datagrid.lstSummaryBar[key] as SummaryBar).colMerge == strMergeColumn)
					{
						delete datagrid.lstSummaryBar[key];
						break;
					}
				}
			}
		}
		
		/*************************************************************
		 * check if a summary key is exist or not
		 * @param key String
		 * @param lst Dictionary
		 * author: Duong Pham
		 * ***********************************************************/
		public function isExistSummaryKey(key : String, lst : Dictionary):Boolean
		{
			var rs  : Boolean = false;
			var keyArr : Array = DictionaryUtil.getKeys(lst);			
			for (var i:int = 0; i < keyArr.length; i++) 
			{
				if(keyArr[i] ==  key)
				{
					rs = true;
					break
				}
			}
			return rs;
		}
		
		/*************************************************************
		 * get first visible column of datagrid
		 * @return value ExAdvancedDataGridColumn
		 * author: Duong Pham
		 * ***********************************************************/
		public function getFirstVisibleColumn(): ExAdvancedDataGridColumn
		{
			var firstVisibleCol : ExAdvancedDataGridColumn;			
			if(this.datagrid.columns && this.datagrid.columns.length >0)
			{
				for each (var col : ExAdvancedDataGridColumn in this.datagrid.columns) 
				{
					if(col.visible)
					{
						firstVisibleCol = col;
						break;
					}
				}
			}
			return firstVisibleCol;
		}
		
		/*************************************************************
		 * check type of format
		 * @param column ExAdvancedDataGridColumn
		 * @param value Number
		 * @return value data is formatted
		 * @author Duong Pham
		 * ***********************************************************/
		public function setDefaultNumberFormat(column:ExAdvancedDataGridColumn, value : Number): String
		{
			var currencyFormatter : CurrencyFormatter = new CurrencyFormatter();
			currencyFormatter.precision = column.precision;
			currencyFormatter.currencySymbol = (column.symbolPrecision.length == 0)? column.symbolPrecision : '';
			return currencyFormatter.format(value);
		}
		
		/*************************************************************
		 * remove zero number
		 * @param total String
		 * @author Duong Pham
		 * ***********************************************************/
		public function removeZeroNumber(total : String): String
		{
			var rs  : String;
			var indexSymbol : int =-1;
			var symbol : String = "";
			if(total.length == 0)
				rs ='0';
			else
			{
				indexSymbol = total.indexOf(' ');
				if( indexSymbol >= 0) // if has currency symbol
				{
					symbol = total.split(' ')[1];
					for (var i:int = indexSymbol -1; i >= 0 ; i--) 
					{
						if(total.charAt(i) == '0' ||total.charAt(i)=='.')
							total = total.slice(0,i);
						else
							break;
					}
					rs = total.slice(0,indexSymbol) + " " + symbol;
				}
				else
				{
					for (var j:int = total.length -1; j >= 0 ; j--) 
					{
						if(total.charAt(j) == '0')
							total = total.slice(0,j);
						else
							break;
					}
					if(total.charAt(total.length-1) == '.')
						rs = total.slice(0,total.length-1);
					else
						rs = total;;
					
				}
			}
			return rs;
		}
		
		/*************************************************************
		 * check if user has input valid column
		 * @param summaryBar SummaryBar
		 * @param strColumnKey : String
		 * @return value Boolean
		 * @author Duong Pham
		 * ***********************************************************/
		public function isInvalidColumnKey(summaryBar : SummaryBar, strColumnKey : String):Boolean
		{
			var lstColKey : Array = summaryBar.strColumnList.split(',');
			var isExist : Boolean = false;
			for (var i:int = 0; i < lstColKey.length; i++) 
			{
				if(lstColKey[i] == strColumnKey)
				{
					isExist = true;
					break;
				}
			}
			return isExist;
		}
		
		/*************************************************************
		 * format footer base on format column or per footer bar
		 * @param column ExAdvancedDataGridColumn
		 * @param value Number
		 * @author Duong Pham
		 * ***********************************************************/
		public function formatBaseOnPatternFooter(column : ExAdvancedDataGridColumn, value : Number):String
		{
			var rs : String ='';
			var pattern : String = '';				
			var index:int=0;
			if(column.footerFormatType == null)
				pattern = column.formatString;
			else
				pattern = column.footerFormatType;				
			if(pattern == '')
				return setDefaultNumberFormat(column, value); 
			if(pattern.indexOf(':') > 0)
			{
				var data : Array = pattern.split(':');
				return (  value + ':' + data[1]);
			}
			
			var formatter : CurrencyFormatter = new CurrencyFormatter ();
			var expression:RegExp=/[#0][#0,.]*[0#]/g;
			var currencyArr:Array=pattern.toString().split(expression);
			var strCurrencyBefore : String = currencyArr[0];
			var strCurrencyAfter : String =currencyArr[1];
			
			var strFormat:Array = pattern.toString().match(expression);
			var arrPrecision:Array=strFormat[0].split(".")
			
			var precision : int =0;
			if (arrPrecision.length == 2 && arrPrecision[1].toString() != "")
			{
				precision=arrPrecision[1].toString().length;
			}
			var numberFormatter : NumberFormatter = new NumberFormatter();
			numberFormatter.thousandsSeparatorTo = ',';
			numberFormatter.decimalSeparatorTo = '.';
			numberFormatter.precision = precision;
			
			var symbolNumberType : String ='';
			if(precision > 0)
			{
				symbolNumberType = arrPrecision[1].toString().charAt(0);
				value = Number(value.toFixed(precision));
			}
			
			if(symbolNumberType == '#')
			{
				rs  = numberFormatter.format(value);
				rs = removeZeroNumber(rs);
				rs = strCurrencyBefore + rs + strCurrencyAfter;
				return rs;
			}
			else
			{
				rs = numberFormatter.format(value);
				rs = strCurrencyBefore + rs + strCurrencyAfter;
				return rs;
			}			
			//return setDefaultNumberFormat(column, value); 
		}
		
		/*************************************************************
		 * get summary bar type
		 * ***********************************************************/
		public function getSummaryBarType(summaryBarKey:String):String
		{
			var typeSummaryBar:String="subtotal";
			if(this.datagrid.lstSummaryBar[summaryBarKey])
			{
				var summaryBar:SummaryBar = this.datagrid.lstSummaryBar[summaryBarKey];
				if(summaryBar && summaryBar.colMerge == SummaryBarConstant.SUMMARYALL)
				{
					if(summaryBar.position == "right")
						return "totalColumn"
					return "total";
				}
			}
			return typeSummaryBar;
		}
		
		/*************************************************************
		 * calculate for total column (this method is calculated  according to row data)
		 * @param strSummaryBarKey String
		 * @param strFunc String
		 * @param item row data
		 * @param column ExAdvancedDataGridColumn
		 * @return Number
		 * @author Duong Pham
		 * ***********************************************************/
		public function calculateTotalColumn(item:Object,column:ExAdvancedDataGridColumn):Number
		{
			var value : Number=0;
			var count:int=0;
			var summaryBar:SummaryBar = column.summaryBar;
			if(summaryBar)
			{
				var arrCalculatedDataField:Array = summaryBar.strColumnList.split(",");
				if(arrCalculatedDataField.length > 0)
				{
					for(var i:int=0; i<arrCalculatedDataField.length; i++)
					{
						if(summaryBar.strFunction == SummaryBarConstant.FUNC_AVERAGE || summaryBar.strFunction ==SummaryBarConstant.FUNC_COUNT )
							count ++;
						if(summaryBar.strFunction != SummaryBarConstant.FUNC_COUNT)
							value += Number(item[arrCalculatedDataField[i]]);
					}
				}
				if(summaryBar.strFunction == SummaryBarConstant.FUNC_COUNT)
					value = count;
				else if (summaryBar.strFunction == SummaryBarConstant.FUNC_AVERAGE)
					value = value/count;
			}
			return value;
		}
		
		/*************************************************************
		 * get summary bar value for total column
		 * @param strSummaryBarKey String
		 * @param strColumnKey String
		 * @param nMergeIndex Number rowIndex
		 * @param bDataFormat Boolean
		 * @return String
		 * @author Duong Pham
		 * ***********************************************************/
		public function getSummaryBarValueForTotalColumn(strSummaryBarKey:String, strColumnKey:String, nMergeIndex:Number, bDataFormat : Boolean):String
		{			
			var returnValue : String ;
			var summaryBar:SummaryBar = this.datagrid.lstSummaryBar[strSummaryBarKey];
			if(summaryBar)
			{
				var item : Object = this.datagrid.dataProvider[nMergeIndex];
				var column:ExAdvancedDataGridColumn = gridOne.getColumnByDataField(summaryBar.totalColDataField) as ExAdvancedDataGridColumn; 
				if(summaryBar.strFunction == SummaryBarConstant.FUNC_CUSTOM)
					returnValue = item[summaryBar.totalColDataField].toString();
				else
					returnValue = calculateTotalColumn(item,column).toString();
			}
			if(isNaN(Number(returnValue)))
			{
				returnValue = "0";
			}
			if(bDataFormat)
				returnValue = formatBaseOnPatternTotal(column,Number(returnValue),item);
			return returnValue;
		}
		
	}
}