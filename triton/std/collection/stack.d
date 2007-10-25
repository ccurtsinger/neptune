module std.collection.stack;

/**
 * Stack implementation based on a linked list method.
 * Uses n*T.sizeof memory for n elements
 */
class Stack(T)
{
	Node* head;
	size_t count;
	
	this()
	{
		head = null;
		count = 0;
	}
	
	~this()
	{
		while(head !is null)
		{
			pop();
		}
	}
	
	size_t size()
	{
		return count;
	}
	
	void push(T t)
	{
		Node* n = new Node;
		
		n.data = t;
		n.prev = head;
		head = n;
		
		count++;
	}
	
	T pop()
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
 * If compact is set, memory usage will reduce on pop().  Otherwise
 * above memory bound applies to the maximum number of elements present
 * at any point.
 */
class FastStack(T, bool compact = true, size_t stride = 16)
{
	T[] data;
	size_t count;
	size_t allocated;
	
	this()
	{
		count = 0;
		allocated = 0;
		data = null;
	}
	
	~this()
	{
		if(data !is null)
			delete data;
	}
	
	size_t size()
	{
		return count;
	}
	
	void push(T t)
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
	
	T pop()
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
