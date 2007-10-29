/**
 * Stack (LIFO) implementations using linked-list and expanding array approaches
 *
 * Authors: Charlie Curtsinger
 * Date: October 29th, 2007
 * Version: 0.1a
 */

module std.collection.stack;

/**
 * Stack implementation based on a linked list method.
 * Uses n*T.sizeof memory for n elements
 *
 * Params:
 *  T = Element type to store in the stack
 */
class Stack(T)
{
	private Node* head;
	private size_t count;
	
	/**
	 * Create an empty stack
	 */
	public this()
	{
		head = null;
		count = 0;
	}
	
	/**
	 * Free all used memory by emptying the stack
	 */
	public ~this()
	{
		while(head !is null)
		{
			pop();
		}
	}
	
	/**
	 * Get the size of the stack
	 *
	 * Returns: The number of elements in the stack
	 */
	public size_t size()
	{
		return count;
	}
	
	/**
	 * Push an element onto the stack
	 *
	 * Params:
	 *  t = Element to push
	 */
	public void push(T t)
	{
		Node* n = new Node;
		
		n.data = t;
		n.prev = head;
		head = n;
		
		count++;
	}
	
	/**
	 * Pop an element off the top of the stack
	 *
	 * Returns: The top element on the stack
	 */
	public T pop()
	in
	{
		assert(head !is null, "Stack empty - unable to execute pop()");
	}
	body
	{
		Node* old = head;
		
		T t = head.data;
		head = head.prev;
		
		count--;
		
		delete old;
		
		return t;
	}
	
	/**
	 * Wrapper struct for elements on the stack
	 */
	struct Node
	{
		T data;
		Node* prev;
	}
}

/**
 * Array-based stack implementation
 * Uses at most n+stride-1*T.sizeof memory for n elements
 *
 * Params:
 *  T = Element type to store in the stack
 *  comact = set if data array should be shrunk when possible
 *  stride = number of elements to increase/decrease data array by when resizing
 */
class FastStack(T, bool compact = true, size_t stride = 16)
{
	private T[] data;
	private size_t count;
	private size_t allocated;
	
	/**
	 * Create an empty stack
	 */
	public this()
	{
		count = 0;
		allocated = 0;
		data = null;
	}
	
	/**
	 * Free used memory by deleting the data array
	 */
	public ~this()
	{
		if(data !is null)
			delete data;
	}
	
	/**
	 * Get the size of the stack
	 *
	 * Returns: The number of elements in the stack
	 */
	public size_t size()
	{
		return count;
	}
	
	/**
	 * Push an element onto the stack.  Resize the data array if no space is available.
	 *
	 * Params:
	 *  t = Element to push
	 */
	public void push(T t)
	{
		if(allocated <= count)
		{
			T[] newdata = new T[allocated + stride];
			
			if(data !is null)
			{
				for(size_t i=0; i<count; i++)
				{
					newdata[i] = data[i];
				}
				
				delete data;
			}
			
			allocated += stride;
			data = newdata;
		}
		
		data[count] = t;
		count++;
	}
	
	/**
	 * Pop an element off the top of the stack.  If 'compact' is set, reduce the data array by 'stride' if possible.
	 *
	 * Returns: The top element on the stack
	 */
	public T pop()
	in
	{
		assert(data !is null, "Stack empty - unable to execute pop()");
	}
	body
	{
		count--;
		T ret = data[count];
		
		static if(compact)
		{
			if(allocated - count >= stride)
			{
				T[] newdata = null;
				
				if(allocated > stride)
				{
					newdata = new T[allocated - stride];
				
					for(size_t i=0; i<count; i++)
					{
						newdata[i] = data[i];
					}
				}
				
				delete data;
				
				allocated -= stride;
				data = newdata;
			}
		}
		
		return ret;
	}
}
