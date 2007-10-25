module std.collection.list;

class List(T)
{
	private Node* head;
	private Node* tail;
	private size_t listSize;
	
	this()
	{
		head = null;
		tail = null;
		listSize = 0;
	}
	
	size_t size()
	{
		return listSize;
	}
	
	/**
	 * Follows the shortest path to locate the Node at `index`
	 */
	private Node* seek(size_t index)
	in
	{
		assert(index >= 0, "Cannot seek to negative List index");
		assert(index < listSize, "Cannot seek beyond List size");
	}
	body
	{
		Node* current;
		size_t pos;
		
		if(index < size() - index)
		{
			current = head;
			pos = 0;
			
			while(pos < index)
			{
				current = current.next;
				pos++;
			}
		}
		else
		{
			current = tail;
			pos = size() - 1;
			
			while(pos > index)
			{
				current = current.prev;
				pos--;
			}
		}
		
		return current;
	}
	
	/**
	 * Get the item at `index`
	 */
	T get(size_t index)
	{
		Node* current = seek(index);		
		return current.data;
	}
	
	/**
	 * Add an item to the front of the list
	 */
	void prepend(T t)
	{
		insert(0, t);
	}
	
	/**
	 * Add an item to the end of the list
	 */
	void append(T t)
	{
		insert(size(), t);
	}
	
	/**
	 * Add an item to the list so it resides at `index` after insertion
	 */
	void insert(size_t index, T t)
	{
		Node* n = new Node;
		n.data = t;
		
		if(index == 0)
		{
			if(head !is null)
			{
				n.next = head;
				n.prev = null;
				head.prev = n;
				head = n;
			}
			else
			{
				n.next = null;
				n.prev = null;
				head = n;
				tail = n;
			}
		}
		else if(index == size)
		{
			n.next = null;
			n.prev = tail;
			tail.next = n;
			tail = n;
		}
		else
		{
			Node* current = seek(index - 1);
			
			n.prev = current;
			n.next = current.next;
			current.next.prev = n;
			current.next = n;
		}
		
		listSize++;
	}
	
	/**
	 * Remove the item at `index`
	 */
	void remove(size_t index)
	{
		Node* current = seek(index);
		
		if(index == 0)
		{
			head = head.next;
			head.prev = null;
			
			// free old head
		}
		else if(index == size() - 1)
		{
			tail = tail.prev;
			tail.next = null;
			
			// free old tail
		}
		else
		{
			current.next.prev = current.prev;
			current.prev.next = current.next;
			
			// free current
		}
		
		listSize--;
	}
	
	struct Node
	{
		T data;
		Node* next;
		Node* prev;
	}
}
