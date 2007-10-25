module std.collection.heap;

import std.stdio;

class Heap(T, bool descending = true, size_t stride = 16)
{
	T[] data;
	size_t allocated;
	size_t elements;
	
	this()
	{
		data = null;
		allocated = 0;
		elements = 0;
	}
	
	void add(T t)
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
	
	T get(size_t index)
	{
	    return data[index];
	}
	
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
