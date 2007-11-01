/**
 * Dynamic memory heap implementation (incomplete)
 *
 * Authors: Charlie Curtsinger
 * Date: October 31st, 2007
 * Version: 0.1b
 */

module std.collection.heap;

/**
 * Array based heap implementation (incomplete)
 *
 * Params:
 *  T = Type to store in heap
 *  descending = true if this is a min-heap
 *  stride = number of elements to increase data array by when it needs expansion
 */
class Heap(T, bool descending = true, size_t stride = 16)
{
	private T[] data;
	private size_t allocated;
	private size_t elements;
	
	/**
	 * Create an empty heap
	 */
	public this()
	{
		data = null;
		allocated = 0;
		elements = 0;
	}
	
	/**
	 * Free used memory by deleting the data array
	 */
	public ~this()
	{
	    if(data !is null)
	    {
	        delete data;
	    }
	}
	
	/**
	 * Add an element to the heap, expanding the data array as necessary
	 */
	public void add(T t)
	{
		if(allocated - elements <= 0)
		{
			T[] newdata = new T[allocated + stride];
			
			for(size_t i=0; i<allocated; i++)
			{
				newdata[i] = data[i];
			}
			
			delete data;
			
			allocated += stride;
			data = newdata;
		}
		
		data[elements] = t;
		
		size_t e = elements;
		elements++;
		
		while(e > 0)
		{
		    heapify(e);
		    e = parentIndex(e);
		}
		
		heapify(0);
	}
	
	/**
	 * Get the index of a particular element's parent
	 *
	 * Params:
	 *  index = element to find parent of
	 *
	 * Returns: index of parent
	 */
	private size_t parentIndex(size_t index)
	{
		// left child
		if(index % 2 == 1)
		{
			return (index - 1) / 2;
		}
		else
		{
			return (index / 2) - 1;
		}
	}
	
	/**
	 * Ensure the heap property holds for an index and its child-heaps
	 *
	 * Params:
	 *  index = root of the sub-heap to heapify
	 *
	 * Returns: true if any change was made to the index or its children
	 */
	private bool heapify(size_t index)
	{
		size_t lchild = (index + 1) * 2 - 1;
		size_t rchild = (index + 1) * 2;
		size_t swap = -1;
		
		if(lchild < elements)
		{
			if(descending)
			{
				if(data[lchild] > data[index])
					swap = lchild;
			}
			else
			{
				if(data[lchild] < data[index])
					swap = lchild;
			}
		}
		
		if(rchild < elements)
		{
			if(descending)
			{
				if(data[rchild] > data[index] && (swap == -1 || data[rchild] > data[swap]))
					swap = rchild;
			}
			else
			{
				if(data[rchild] < data[index] && (swap == -1 || data[rchild] < data[swap]))
					swap = rchild;
			}
		}
		
		if(swap != -1)
		{
			T temp = data[index];
			data[index] = data[swap];
			data[swap] = temp;
			
			heapify(swap);
			
			return true;
		}
		
		return false;
	}
}
