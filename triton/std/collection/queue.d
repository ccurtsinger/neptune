module std.collection.queue;

/**
 * Queue implementation based on a linked list method.
 * Uses n*T.sizeof memory for n elements
 */
class Queue(T)
{
	Node* head;
	Node* tail;
	size_t count;

	this()
	{
		head = null;
		tail = null;
		count = 0;
	}

	~this()
	{
		while(head !is null)
		{
			dequeue();
		}
	}

	size_t size()
	{
		return count;
	}

	void enqueue(T t)
	{
		Node* n = new Node;

		n.data = t;
        n.next = null;

        if(tail !is null)
        {
            tail.next = n;
            tail = n;
        }
        else
        {
            head = n;
            tail = n;
        }
        
        count++;
	}

	T dequeue()
	in
	{
	    assert(head !is null, "Attempted to dequeue from an empty Queue");
	}
	body
	{
        T t = head.data;
        
        Node* old = head;
        head = head.next;
        
        delete old;
        
        return t;
	}

	struct Node
	{
		T data;
		Node* next;
	}
}
