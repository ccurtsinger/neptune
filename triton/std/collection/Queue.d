/**
 * Queue (FIFO) implementations using linked-list and expanding-circular-buffer approaches
 *
 * Authors: Charlie Curtsinger
 * Date: October 31st, 2007
 * Version: 0.1b
 */

module std.collection.Queue;

/**
 * Queue implementation based on a linked list method.
 * Uses n*T.sizeof memory for n elements
 *
 * Params:
 *  T = Type to store in queue
 */
class Queue(T)
{
	private Node* head;
	private Node* tail;
	private size_t count;

    /**
     * Create an empty queue
     */
	public this()
	{
		head = null;
		tail = null;
		count = 0;
	}

    /**
     * Free all used memory by emptying queue
     */
	public ~this()
	{
		while(head !is null)
		{
			dequeue();
		}
	}

    /**
     * Get the size of the queue
     *
     * Returns: The number of elements in the queue
     */
	public size_t size()
	{
		return count;
	}

    /**
     * Enqueue an element
     *
     * Params:
     *  t = Element to enqueue
     */
	public void enqueue(T t)
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

    /**
     * Dequeue an element
     *
     * Returns: The oldest (first) element in the queue
     */
	public T dequeue()
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

    /**
     * Wrapper struct for elements in the Queue
     */
	struct Node
	{
		T data;
		Node* next;
	}
}
