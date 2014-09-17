/*
 * Created by SharpDevelop.
 * User: Kuzin.A
 * Date: 16.09.2014
 * Time: 23:00
 * 
 * 
 */
using System;
using System.Collections.Generic;

namespace Sudoku
{
	public sealed class Field
	{
		const int FieldSize = 9;
		
		readonly Cell[,] cells;
		readonly AreaCollection rows, columns, squares;
		readonly System.Collections.ObjectModel.ReadOnlyCollection<int> allValues;
		
		public Field()
		{
			int[] allValuesArray = new int[Size];
			for (int i = 0; i < Size; i++)
				allValuesArray[i] = i + 1;
			allValues = new System.Collections.ObjectModel.ReadOnlyCollection<int>(allValuesArray);
			
			cells = new Cell[Size,Size];
			for (int row = 0; row < Size; row++)
				for (int col = 0; col < Size; col++)
					cells[row,col] = new Cell();
			
			rows = new AreaCollection(this, (field, areaIndex, index) => field[areaIndex, index], AreaType.Row);
			columns = new AreaCollection(this, (field, areaIndex, index) => field[index, areaIndex], AreaType.Column);
			squares = new AreaCollection(this, (field, areaIndex, index) => field[areaIndex / 3 * 3 + index / 3, areaIndex % 3 * 3 + index % 3], AreaType.Square);
		}
		
		public System.Collections.ObjectModel.ReadOnlyCollection<int> AllValues { get { return allValues; } }
		
		public int Size { get { return FieldSize; } }
		
		public Cell this[int row, int col] { get { return cells[row,col]; } }
		
		public AreaCollection Rows { get { return rows; } }
		public AreaCollection Columns { get { return columns; } }
		public AreaCollection Squares { get { return squares; } }
		
		public void Init(int[][] values)
		{
			for (int row = 0; row < Size; row++)
			{
				for (int col = 0; col < Size; col++)
				{
					var cell = this[row,col];
					if (values[row][col] > 0)
						cell.Variants.Add(values[row][col]);
					else
					{
						for (int val = 1; val <= Size; val++)
							cell.Variants.Add(val);
					}
				}
			}
		}
		
		public bool GetCellCoordinates(Cell cell, out int row, out int column)
		{
			for (int rowIndex = 0; rowIndex < Size; rowIndex++)
			{
				for (int colIndex = 0; colIndex < Size; colIndex++)
				{
					if (cells[rowIndex,colIndex] == cell)
					{
						row = rowIndex;
						column = colIndex;
						return true;
					}
				}
			}
			
			row = -1;
			column = -1;
			return false;
		}
	}
	
	public sealed class AreaCollection : IReadOnlyList<Area>
	{
		readonly Field field;
		readonly Area[] areas;
		
		public AreaCollection(Field field, Func<Field,int,int,Cell> cellGetter, AreaType areasType)
		{
			this.field = field;
			areas = new Area[field.Size];
			for (int i = 0; i < field.Size; i++)
				areas[i] = new Area(field, i, cellGetter, areasType);
		}

		public IEnumerator<Area> GetEnumerator()
		{
			return ((IEnumerable<Area>)areas).GetEnumerator();
		}

		System.Collections.IEnumerator System.Collections.IEnumerable.GetEnumerator()
		{
			return GetEnumerator();
		}

		public Area this[int index] { get { return areas[index]; } }

		public int Count { get { return field.Size; } }
	}
	
	public sealed class Area : IReadOnlyList<Cell>
	{
		readonly Field field;
		readonly int areaIndex;
		readonly Func<Field,int,int,Cell> cellGetter;
		readonly AreaType type;
		
		public Area(Field field, int areaIndex, Func<Field,int,int,Cell> cellGetter, AreaType type)
		{
			this.field = field;
			this.areaIndex = areaIndex;
			this.cellGetter = cellGetter;
			this.type;
		}
		
		public AreaType Type { get { return type; } }
		
		public SortedSet<int> GetValues()
		{
			var values = new SortedSet<int>();
			foreach (var cell in this)
			{
				int? cellValue = cell.Value;
				if (cellValue != null)
					values.Add(cellValue.Value);
			}
			return values;
		}
		
		public SortedSet<int> GetMissingValues()
		{
			var values = new SortedSet<int>(field.AllValues);
			foreach (var cell in this)
				foreach (int val in cell.Variants)
					values.Remove(val);
			return values;
		}
		
		public IEnumerator<Cell> GetEnumerator()
		{
			for (int i = 0; i < Count; i++)
				yield return this[i];
		}
		
		System.Collections.IEnumerator System.Collections.IEnumerable.GetEnumerator()
		{
			return GetEnumerator();
		}

		public Cell this[int index] { get { return cellGetter(field, areaIndex, index); } }

		public int Count { get { return field.Size; } }
	}
	
	public class Cell
	{
		readonly SortedSet<int> variants = new SortedSet<int>();
		
		public int? Value
		{
			get
			{
				if (variants.Count == 1)
					return variants.Min;
				else
					return null;
			}
		}
		
		public SortedSet<int> Variants { get { return variants; } }
	}
	
	public enum AreaType
	{
		Row,
		Column,
		Square
	}
	
	public struct Point
	{
		public int X { get; set; }
		public int Y { get; set; }
	}
}
