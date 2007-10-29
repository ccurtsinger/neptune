module std.collection.queue;

/**
 * Queue implementation based on a linked list method.
 * Uses n*T.sizeof memory for n elements
 */
class Queue(T)
{
	private Node* head;
	private Node* tail;
	private size_t count;

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
	    count--;
	    
        T t = head.data;
        
        if(head == tail)
        {
            delete head;
            head = null;
            tail = null;
        }
        else
        {
            Node* old = head;
            head = head.next;
            delete old;
        }
        
        return t;
	}

	struct Node
	{
		T data;
		Node* next;
	}
}
