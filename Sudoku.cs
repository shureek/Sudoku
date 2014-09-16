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
		
		readonly Cell[,] variants;
		readonly AreaCollection rows, columns, squares;
		readonly System.Collections.ObjectModel.ReadOnlyCollection<int> allValues;
		
		public Field()
		{
			int[] allValuesArray = new int[Size];
			for (int i = 0; i < Size; i++)
				allValuesArray[i] = i + 1;
			allValues = new System.Collections.ObjectModel.ReadOnlyCollection<int>(allValuesArray);
			
			variants = new Cell[Size,Size];
			for (int row = 0; row < Size; row++)
				for (int col = 0; col < Size; col++)
					variants[row,col] = new Cell();
			
			rows = new AreaCollection(this, (field, areaIndex, index) => field[areaIndex, index]);
			columns = new AreaCollection(this, (field, areaIndex, index) => field[index, areaIndex]);
			squares = new AreaCollection(this, (field, areaIndex, index) => field[areaIndex / 3 * 3 + index / 3, areaIndex % 3 * 3 + index % 3]);
		}
		
		public System.Collections.ObjectModel.ReadOnlyCollection<int> AllValues { get { return allValues; } }
		
		public int Size { get { return FieldSize; } }
		
		public Cell this[int row, int col] { get { return variants[row,col]; } }
		
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
	}
	
	public sealed class AreaCollection : IReadOnlyList<Area>
	{
		readonly Field field;
		readonly Area[] areas;
		
		public AreaCollection(Field field, Func<Field,int,int,Cell> cellGetter)
		{
			this.field = field;
			areas = new Area[field.Size];
			for (int i = 0; i < field.Size; i++)
				areas[i] = new Area(field, i, cellGetter);
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
		
		public Area(Field field, int areaIndex, Func<Field,int,int,Cell> cellGetter)
		{
			this.field = field;
			this.areaIndex = areaIndex;
			this.cellGetter = cellGetter;
		}
		
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
}
