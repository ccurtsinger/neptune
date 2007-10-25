module std.collection.queue;

class Queue(T)
{
	Node* head;

	this()
	{
		head = null;
	}
	
	/**
	 * Return the current item
	 */
	T current()
	{
		return head.data;
	}
	
	/**
	 * Adds an item one place before the current head
	 */
	void add(T t)
	{
		Node* n = new Node;
		n.data = t;
		
		if(head !is null)
		{
			n.next = head;
			n.prev = head.prev;
			head.prev.next = n;
			head.prev = n;
		}
		else
		{
			head = n;
			n.next = n;
			n.prev = n;
		}
	}
	
	/**
	 * Removes the current item
	 */
	T remove()
	in
	{
		assert(head !is null, "Cannot remove an item from an empty Queue");
	}
	body
	{
		T t = head.data;
		Node* old = head;
		
		head.prev.next = head.next;
		head.next.prev = head.prev;
		
		head = head.next;
		
		delete old;
		
		return t;
	}
	
	/**
	 * Move to the next item
	 */
	void forward()
	in
	{
		assert(head !is null, "Cannot move forward in an empty Queue");
	}
	body
	{
		head = head.next;
	}
	
	/**
	 * Move to the previous item
	 */
	void back()
	in
	{
		assert(head !is null, "Cannot move back in an empty Queue");
	}
	body
	{
		head = head.prev;
	}
	
	struct Node
	{
		T data;
		Node* next;
		Node* prev;
	}
}
