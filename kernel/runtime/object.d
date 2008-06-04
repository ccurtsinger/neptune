/**
 * Definition for base language types
 * 
 * Derived from copyrighted work by Walter Bright (www.digitalmars.com)
 * and Sean Kelly (www.dsource.org/projects/tango)
 *
 * Copyright: 2008 The Neptune Project
 */

/*
 *  Copyright (C) 2004-2008 by Digital Mars, www.digitalmars.com
 *  Written by Walter Bright
 *
 *  This software is provided 'as-is', without any express or implied
 *  warranty. In no event will the authors be held liable for any damages
 *  arising from the use of this software.
 *
 *  Permission is granted to anyone to use this software for any purpose,
 *  including commercial applications, and to alter it and redistribute it
 *  freely, in both source and binary form, subject to the following
 *  restrictions:
 *
 *  o  The origin of this software must not be misrepresented; you must not
 *     claim that you wrote the original software. If you use this software
 *     in a product, an acknowledgment in the product documentation would be
 *     appreciated but is not required.
 *  o  Altered source versions must be plainly marked as such, and must not
 *     be misrepresented as being the original software.
 *  o  This notice may not be removed or altered from any source
 *     distribution.
 */

module object;

alias uint size_t;
alias uint hash_t;
alias int ptrdiff_t;

/**
 * All D class objects inherit from Object.
 */
class Object
{
    /**
     * Convert Object to a human readable string.
     */
    char[] toString()
    {
        return this.classinfo.name;
    }

    /**
     * Compute hash function for Object.
     */
    hash_t toHash()
    {
        return cast(hash_t)cast(void*)this;
    }

    /**
     * Compare with another Object
     */
    int opCmp(Object o)
    {
        return this !is o;
    }

    /**
     * Returns !=0 if this object does have the same contents as obj.
     */
    int opEquals(Object o)
    {
        return cast(int)(this is o);
    }

    interface Monitor
    {
        void lock();
        void unlock();
    }
}

/**
 * Information about an interface.
 * A pointer to this appears as the first entry in the interface's vtbl[].
 */
struct Interface
{
    ClassInfo classinfo;
    void*[] vtbl;
    ptrdiff_t offset;
}

/**
 * Runtime type information about a class. Can be retrieved for any class type
 * or instance by using the .classinfo property.
 * A pointer to this appears as the first entry in the class's vtbl[].
 */
class ClassInfo : Object
{
    byte[] init;
    char[] name;
    void*[] vtbl;
    Interface[] interfaces;
    ClassInfo base;
    void* destructor;
    void function(Object) classInvariant;
    uint flags;
    void* deallocator;
    OffsetTypeInfo[] offTi;
    void function(Object) defaultConstructor;

}

/**
 * Array of pairs giving the offset and type information for each
 * member in an aggregate.
 */
struct OffsetTypeInfo
{
    size_t   offset;    /// Offset of member from start of object
    TypeInfo ti;        /// TypeInfo for this member
}

/**
 * Runtime type information about a type.
 * Can be retrieved for any type using a
 * <a href="../expression.html#typeidexpression">TypeidExpression</a>.
 */
class TypeInfo
{
    /// Get TypeInfo for 'next' type, as defined by what kind of type this is,
    /// null if none.
    TypeInfo next()
    {
        return null;
    }

    size_t tsize()
    {
        return 0;
    }

    /// Return default initializer, null if default initialize to 0
    void[] init()
    {
        return null;
    }
}

class TypeInfo_Typedef : TypeInfo
{
    size_t tsize()
    {
        return base.tsize();
    }

    TypeInfo next()
    {
        return base.next();
    }

    void[] init()
    {
        return m_init.length ? m_init : base.init();
    }

    TypeInfo base;
    char[] name;
    void[] m_init;
}

class TypeInfo_Enum : TypeInfo_Typedef
{
}

class TypeInfo_Pointer : TypeInfo
{
    size_t tsize()
    {
        return (void*).sizeof;
    }

    TypeInfo next()
    {
        return m_next;
    }

    TypeInfo m_next;
}

class TypeInfo_Array : TypeInfo
{
    size_t tsize()
    {
        return (void[]).sizeof;
    }

    TypeInfo value;

    TypeInfo next()
    {
        return value;
    }
}

class TypeInfo_StaticArray : TypeInfo
{
    size_t tsize()
    {
        return len * value.tsize();
    }

    void[] init()
    {
        return value.init();
    }

    TypeInfo next()
    {
        return value;
    }

    TypeInfo value;
    size_t len;
}

class TypeInfo_AssociativeArray : TypeInfo
{
    size_t tsize()
    {
        return (char[int]).sizeof;
    }

    TypeInfo next()
    {
        return value;
    }

    TypeInfo value;
    TypeInfo key;
}

class TypeInfo_Function : TypeInfo
{
    size_t tsize()
    {
        return 0;       // no size for functions
    }

    TypeInfo next;
}

class TypeInfo_Delegate : TypeInfo
{
    size_t tsize()
    {
        alias int delegate() dg;
        return dg.sizeof;
    }

    TypeInfo next;
}

class TypeInfo_Class : TypeInfo
{
    size_t tsize()
    {
        return Object.sizeof;
    }

    ClassInfo info;
}

class TypeInfo_Interface : TypeInfo
{
    size_t tsize()
    {
        return Object.sizeof;
    }

    ClassInfo info;
}

class TypeInfo_Struct : TypeInfo
{
    size_t tsize()
    {
        return init.length;
    }

    void[] init()
    {
        return m_init;
    }

    char[] name;
    void[] m_init;      // initializer; init.ptr == null if 0 initialize

    hash_t function(void*)    xtoHash;
    int function(void*,void*) xopEquals;
    int function(void*,void*) xopCmp;
    char[] function(void*)    xtoString;

    uint m_flags;
}

class TypeInfo_Tuple : TypeInfo
{
    TypeInfo[] elements;

    size_t tsize()
    {
        assert(0);
    }
}

class Exception : Object
{
    char[]      msg;
    char[]      file;
    size_t      line;
    Exception   next;

    this(char[] msg, Exception next = null)
    {
        this.msg = msg;
        this.next = next;
    }

    this(char[] msg, char[] file, size_t line, Exception next = null)
    {
        this(msg, next);
        this.file = file;
        this.line = line;
    }

    char[] toString()
    {
        return msg;
    }
}

/***********************
 * Information about each module.
 */
class ModuleInfo
{
    char name[];
    ModuleInfo importedModules[];
    ClassInfo localClasses[];

    uint flags;		// initialization state

    void (*ctor)();
    void (*dtor)();
    void (*unitTest)();
}

/************************
 * Monitor stuff
 */

alias Object.Monitor IMonitor;

struct Monitor
{
	IMonitor impl;
}

Monitor* getMonitor(Object h)
{
	return cast(Monitor*) (cast(void**)h)[1];
}

void setMonitor(Object h, Monitor* m)
{
	(cast(void**)h)[1] = m;
}

/**
 * Tuple for file/memory permission passing
 */
struct Permission
{
    bool r;
    bool w;
    bool x;
    
    static Permission opCall(char[3] s)
    {
        Permission p;
        p.r = s[0] == 'r';
        p.w = s[1] == 'w';
        p.x = s[2] == 'x';
        return p;
    }
}
