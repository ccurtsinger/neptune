/**
 * Associative array support
 *
 * Copyright: 2008 The Neptune Project
 */
 
module aarray;
 
import kernel.core;

import std.mem;

struct Array
{
    size_t length;
    void* ptr;
}

/**
 * The associative array data passed to handling functions
 */
struct AssociativeArray
{
    AssociativeArrayNode** head = null;
}

/**
 * Associative array node
 */
struct AssociativeArrayNode
{
    AssociativeArrayNode* next;
    void* key;
    void* data;
}

/**
 * Determine number of entries in associative array.
 */
extern (C) size_t _aaLen(AssociativeArray aa)
{
    if(aa.head is null)
        return 0;
    
    AssociativeArrayNode* c = *aa.head;
    size_t count = 0;
    
    while(c !is null)
    {
        count++;
        c = c.next;
    }
    
    return count;
}

/**
 * Get pointer to value in associative array indexed by key.
 * Add entry for key if it is not already there.
 */
extern (C) void *_aaGetp(AssociativeArray* aa, TypeInfo keyti, size_t valuesize, void *pkey)
{
    void* p = _aaInp(*aa, keyti, pkey);
    
    if(p !is null)
        return p;
    
    AssociativeArrayNode* node = cast(AssociativeArrayNode*)heap.allocate(AssociativeArrayNode.sizeof);
    node.key = heap.allocate(keyti.tsize());
    node.data = heap.allocate(valuesize);
    
    memcpy(node.key, pkey, keyti.tsize());

    if(aa.head is null)
    {
        aa.head = cast(AssociativeArrayNode**)heap.allocate((AssociativeArrayNode*).sizeof);
        *aa.head = node;
    }
    else
    {
        AssociativeArrayNode* c = *aa.head;
        
        while(c.next !is null)
        {
            c = c.next;
        }
        
        c.next = node;
    }
    
    return node.data;
}

/**
 * Get pointer to value in associative array indexed by key.
 * Returns null if it is not already there.
 */
extern (C) void *_aaGetRvaluep(AssociativeArray aa, TypeInfo keyti, size_t valuesize, void *pkey)
{
    return _aaInp(aa, keyti, pkey);
}

/**
 * Determine if key is in aa.
 * Returns:
 *      null    not in aa
 *      !=null  in aa, return pointer to value
 */
extern (C) void* _aaInp(AssociativeArray aa, TypeInfo keyti, void *pkey)
{
    if(aa.head is null)
        return null;
        
    AssociativeArrayNode* c = *aa.head;
    
    while(c !is null)
    {
        if(memcmp(c.key, pkey, keyti.tsize()) == 0)
            return c.data;
        
        c = c.next;
    }
    
    return null;
}

/**
 * Delete key entry in aa[].
 * If key is not in aa[], do nothing.
 */
extern (C) void _aaDelp(AssociativeArray aa, TypeInfo keyti, void *pkey)
{
    AssociativeArrayNode* prev = null;
    AssociativeArrayNode* c = *aa.head;
    
    while(c !is null)
    {
        if(memcmp(c.key, pkey, keyti.tsize()) == 0)
        {
            if(prev is null)
            {
                *aa.head = c.next;
            }
            else
            {
                prev.next = c.next;
            }
            
            heap.free(c.key);
            heap.free(c.data);
            heap.free(c);
            
            return;
        }
        
        prev = c;
        c = c.next;
    }
}

/**
 * Produce array of values from aa.
 */
extern (C) Array _aaValues(AssociativeArray aa, size_t keysize, size_t valuesize)
{
    Array ret;
    
    if(aa.head is null)
    {
        ret.length = 0;
        ret.ptr = null;
        return ret;
    }
        
    ret.length = _aaLen(aa);
    ret.ptr = heap.allocate(ret.length * valuesize);
    
    size_t offset = 0;
        
    AssociativeArrayNode* c = *aa.head;
    
    while(c !is null)
    {
        memcpy(ret.ptr + offset, c.data, valuesize);
        
        offset += valuesize;
        c = c.next;
    }
    
    return ret;
}

/**
 * Rehash an array.
 */
extern (C) AssociativeArray _aaRehash(AssociativeArray* paa, TypeInfo keyti)
{
    return *paa;
}

/**
 * Produce array of N byte keys from aa.
 */
extern (C) Array _aaKeys(AssociativeArray aa, size_t keysize)
{
    Array ret;
    
    if(aa.head is null)
    {
        ret.length = 0;
        ret.ptr = null;
        return ret;
    }
        
    ret.length = _aaLen(aa);
    ret.ptr = heap.allocate(ret.length * keysize);
    
    size_t offset = 0;
        
    AssociativeArrayNode* c = *aa.head;
    
    while(c !is null)
    {
        memcpy(ret.ptr + offset, c.key, keysize);
        
        offset += keysize;
        c = c.next;
    }
    
    return ret;
}

/**
 * 'apply' for associative arrays - to support foreach
 */
extern (C) int _aaApply(AssociativeArray aa, size_t keysize, int delegate(void *) dg)
{
    int result;
    
    if(aa.head is null)
        return result;
    
    AssociativeArrayNode* c = *aa.head;
    
    while(c !is null)
    {
        result = dg(c.data);
        
        if(result)
            break;
        
        c = c.next;
    }
    
    return result;
}

extern (C) int _aaApply2(AssociativeArray aa, size_t keysize, int delegate(void *, void *) dg)
{
    int result;
    
    if(aa.head is null)
        return result;
    
    AssociativeArrayNode* c = *aa.head;
    
    while(c !is null)
    {
        result = dg(c.key, c.data);
        
        if(result)
            break;
        
        c = c.next;
    }
    
    return result;
}
