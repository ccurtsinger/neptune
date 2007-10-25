module std.collection.stack;

class Stack(T)
{
	Node* head;
	
	this()
	{
		head = null;
	}
	
	void push(T t)
	{
		Node* n = new Node;
		
		n.data = t;
		n.prev = head;
		head = n;
	}
	
	T pop()
	in
	{
		assert(head != null, "Stack empty - unable to execute pop()");
	}
	body
	{
		T t = head.data;
		head = head.prev;
		
		// free old head
		
		return t;
	}
	
	struct Node
	{
		T data;
		Node* prev;
	}
}
