/**
 * Queue (FIFO) implementations using linked-list and expanding-circular-buffer approaches
 *
 * Authors: Charlie Curtsinger
 * Date: October 31st, 2007
 * Version: 0.1b
 */

module std.collection.queue;

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

/**
 * Array-based queue implementation (circular buffer)
 * Uses at most n+stride-1*T.sizeof memory for n elements
 *
 * Params:
 *  T = Type to store in queue
 *  compact = true if allocated data array should shrink when possible
 *  stride = number of elements to increase/decrease data array by when changing size
 */
class FastQueue(T, bool compact = true, size_t stride = 16)
{
    private T[] data;
	private size_t base;
	private size_t count;
	private size_t allocated;
	
	/**
     * Create an empty queue
     */
	public this()
	{
	    base = 0;
	    count = 0;
	    allocated = 0;
	    data = null;
	}
	
	/**
     * Free the data array
     */
	public ~this()
	{
	    if(data !is null)
	    {
            delete data;
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
     * Enqueue an element.  If not enough space is available, allocated a new data array.
     *
     * Params:
     *  t = Element to enqueue
     */
	public void enqueue(T t)
	{
	    if(allocated <= count)
	    {
	        T[] newdata = new T[allocated + stride];
	        
	        if(data !is null)
	        {
	            for(size_t i=0; i<count; i++)
	            {
	                newdata[i] = data[(base + i)%allocated];
	            }
	            
	            base = 0;
	            
	            delete data;
	        }
	        
	        allocated += stride;
            data = newdata;
	    }
	    
	    size_t index = base + count;
	    
	    while(index >= allocated)
        {
            index -= allocated;
        }
        
        data[index] = t;
        count++;
	}
	
	/**
     * Dequeue an element.  If compact is set, shrink allocated size by 'stride' if possible
     *
     * Returns: The oldest (first) element in the queue
     */
	public T dequeue()
	in
	{
	    assert(data !is null && count > 0, "Attempted to dequeue from an empty Queue");
	}
	body
	{
	    T t = data[base];
	    
	    base++;
	    
	    while(base >= allocated)
	    {
	        base -= allocated;
	    }
	    
	    count--;
	    
	    static if(compact)
	    {
	        if(allocated - count >= stride && allocated > stride)
	        {
	            T[] newdata = new T[allocated - stride];
	                
                for(size_t i=0; i<count; i++)
                {
                    newdata[i] = data[(base + i)%allocated];
                }
                
                base = 0;
	            
	            delete data;
	            allocated -= stride;
	            data = newdata;
	        }
	    }
	    
	    return t;
	}
}
