/**
 * Wait queue used for blocking threads on resources
 *
 * Authors: Charlie Curtsinger
 * Date: March 1st, 2008
 * Version: 0.3
 *
 * Copyright: 2008 Charlie Curtsinger
 */

module kernel.task.waitqueue;

import kernel.task.thread;

class WaitCondition
{
    Thread thread;
    ulong value;
    
    public this(Thread thread, ulong value)
    {
        this.thread = thread;
        this.value = value;
    }
}

public class WaitQueue
{
    private Node* head;
    private size_t count;
    
    public this()
    {
        head = null;
        count = 0;
    }
    
    public size_t length()
    {
        return count;
    }
    
    public void add(WaitCondition c)
    {
        Node* n = new Node;
        n.cond = c;
        
        Node* prev = null;
        Node* current = head;
        
        while(current !is null && current.cond.value < c.value)
        {
            prev = current;
            current = current.next;
        }
        
        if(prev is null)
        {
            n.next = current;
            head = n;
        }
        else
        {
            prev.next = n;
            n.next = current;
        }
        
        count++;
    }
    
    public WaitCondition peek()
    in
    {
        assert(head !is null);
    }
    body
    {
        return head.cond;
    }
    
    public WaitCondition get()
    in
    {
        assert(head !is null);
    }
    body
    {
        count--;
        Node* n = head;
        head = n.next;
        
        WaitCondition c = n.cond;
        delete n;
        
        return c;
    }
    
    private struct Node
    {
        WaitCondition cond;
        Node* next;
    }
}
