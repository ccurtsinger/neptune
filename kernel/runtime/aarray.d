/**
 * Associative array support
 *
 * Copyright: 2008 The Neptune Project
 */
 
module aarray;
 
import kernel.core;

import std.mem;

/// Struct representation of an array
struct Array
{
    size_t length;
    void* ptr;
}

/// The associative array data passed to handling functions
struct AssociativeArray
{
    AssociativeArrayNode** head = null;
}

/// Associative array node
struct AssociativeArrayNode
{
    AssociativeArrayNode* next;
    void* key;
    void* data;
}

/**
 * Determine number of entries in associative array.
 *
 * Params:
 *  aa = the associative array
 *
 * Returns: the number of nodes in the associative array
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
 * Get a pointer to an element in an associative array.
 * If element isn't present, allocate space for it
 *
 * Params:
 *  aa = pointer to the associative array object
 *  keyti = typeinfo for the associative array's key type
 *  valuesize = type size for the associative array's data type
 *  pkey = pointer to the key data for this lookup/insertion
 *
 * Returns: pointer to the data element for the given key in aa
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
 * Get a pointer to an element in an associative array
 *
 * Params:
 *  aa = associative array
 *  keyti = typeinfo for the associative arrays key type
 *  valuesize = type size for the associative array's data type
 *  pkey = pointer to the key data for this lookup
 *
 * Returns: null if key was not found, or a pointer to the found data memory location
 */
extern (C) void *_aaGetRvaluep(AssociativeArray aa, TypeInfo keyti, size_t valuesize, void *pkey)
{
    return _aaInp(aa, keyti, pkey);
}

/**
 * Find a key in an associative array
 *
 * Params:
 *  aa = associative array
 *  keyti = typeinfo for the associative array key type
 *  pkey = pointer to the key data
 *
 * Returns: null if key isn't found, otherwise a pointer to the key's data
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
 * Remove a key from an associative array
 *
 * Params:
 *  aa = associative array
 *  keyti = typeinfo for the associative array key type
 *  pkey = pointer to the key data
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
 * Generate an array of values from the associative array
 *
 * Params:
 *  aa = associative array
 *  keysize = type size for the associative array key type
 *  valuesize = type size for the associative array value type
 *
 * Returns: array of values
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
 * Rehash an associative array
 *
 * Params:
 *  aa = pointer to the associative array
 *  keyti = typeinfo for the associative array key type
 *
 * Returns: the rehashed associative array
 */
extern (C) AssociativeArray _aaRehash(AssociativeArray* aa, TypeInfo keyti)
{
    return *aa;
}

/**
 * Generate an array of keys from the associative array
 *
 * Params:
 *  aa = associative array
 *  keysize = type size for the associative array key type
 *  valuesize = type size for the associative array value type
 *
 * Returns: array of keys
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
 * Support for foreach loops on an associative array
 *
 * Params:
 *  aa = associative array
 *  keysize = type size for the associative array key type
 *  dg = delegate to apply to each element in the associative array
 *
 * Returns: result of dg
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

/**
 * Support for foreach loops on an associative array using an index parameter
 *
 * Params:
 *  aa = associative array
 *  keysize = type size for the associative array key type
 *  dg = delegate to apply to each element in the associative array
 *
 * Returns: result of dg
 */
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
