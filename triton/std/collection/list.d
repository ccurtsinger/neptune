/**
 * Linked List implementation (doubly-linked)
 *
 * Authors: Charlie Curtsinger
 * Date: October 29th, 2007
 * Version: 0.1a
 */

module std.collection.list;

/**
 * Linked list implementation
 *
 * Params:
 *  T = Element type to store in this list
 */
class List(T)
{
	private Node* head;
	private Node* tail;
	private size_t listSize;
	
	/**
	 * Create an empty list
	 */
	public this()
	{
		head = null;
		tail = null;
		listSize = 0;
	}
	
	/**
	 * Free all used memory by emptying the list
	 */
	public ~this()
	{
	    while(size() > 0)
	    {
	        remove(0);
	    }
	}
	
	/**
	 * Get the size of the list
	 *
	 * Returns: The number of elements in the list
	 */
	public size_t size()
	{
		return listSize;
	}
	
	/**
	 * Follows the shortest path to locate the Node at `index`
	 *
	 * Params:
	 *  index = index to seek to
	 *
	 * Returns: Node* to the requested index
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
	 * Get the item at 'index'
	 *
	 * Params:
	 *  index = index to seek to and return element at
	 *
	 * Returns: Element at index
	 */
	public T get(size_t index)
	{
		Node* current = seek(index);		
		return current.data;
	}
	
	/**
	 * Add an item to the front of the list
	 *
	 * Params:
	 *  t = Element to add
	 */
	public void prepend(T t)
	{
		insert(0, t);
	}
	
	/**
	 * Add an item to the end of the list
	 *
	 * Params:
	 *  t = Element to add
	 */
	public void append(T t)
	{
		insert(size(), t);
	}
	
	/**
	 * Add an item to the list so it resides at `index` after insertion
	 *
	 * Params:
	 *  index = index that t should be at after adding it to the list
	 *  t = Element to add
	 */
	public void insert(size_t index, T t)
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
	 * Remove the item at 'index'
	 *
	 * Params:
	 *  index = index to remove
	 *
	 * Returns: The element at the removed index
	 */
	public T remove(size_t index)
	{
		Node* current = seek(index);
		T t = current.data;
		
		Node* old;
		
		if(index == 0)
		{
			old = head;
			
			head = head.next;
			head.prev = null;
			
			delete old;
		}
		else if(index == size() - 1)
		{
			old = tail;
			
			tail = tail.prev;
			tail.next = null;
			
			delete old;
		}
		else
		{
			current.next.prev = current.prev;
			current.prev.next = current.next;
			
			delete current;
		}
		
		listSize--;
		
		return t;
	}
	
	/**
	 * Wrapper struct for elements in the list
	 */
	struct Node
	{
		T data;
		Node* next;
		Node* prev;
	}
}
