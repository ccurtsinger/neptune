/**
 * Language support for invariant types
 *
 * Copyright: 2008 The Neptune Project
 */

/*
 * Placed into the Public Domain
 * written by Walter Bright
 * www.digitalmars.com
 */

/**
 * Call class invariants on a given object
 */
void _d_invariant(Object o)
{
    assert(o !is null, "Attempted to run _d_invariant on null object");

    ClassInfo c = o.classinfo;

    do
    {
        if (c.classInvariant)
            (*c.classInvariant)(o);

        c = c.base;
        
    } while(c);
}
