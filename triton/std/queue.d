module std.queue;

class Queue(T, size_t stride = 4)
{
    private Node* head;
    private Node* tail;
    private size_t count;
    
    public this()
    {
        head = null;
        tail = null;
        count = 0;
    }
    
    public ~this()
    {
        Node* n = head;
        
        while(count > 0)
        {
            assert(n !is null, "Unexpected null element in non-empty queue");
            head = n.next;
            delete n;
            n = head;
            count--;
        }
    }
    
    public void add(T t)
    {
        Node* n = new Node;
        
        n.element = t;
        
        if(count == 0)
        {
            head = n;
            tail = n;
        }
        else
        {
            tail.next = n;
            tail = n;
        }
        
        count++;
    }
    
    public T get()
    in
    {
        assert(count > 0, "get() called on an empty queue");
    }
    body
    {
        Node* n = head;
        head = head.next;
        
        count--;
        
        T t = n.element;
        delete n;
        
        if(count == 0)
        {
            head = null;
            tail = null;
        }
        
        return t;
    }
    
    public T peek()
    in
    {
        assert(count > 0, "peek() called on an empty queue");
    }
    body
    {
        return head.element;
    }
    
    public size_t size()
    {
        return count;
    }
    
    struct Node
    {
        T element;
        Node* next;
    }
}
