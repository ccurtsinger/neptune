/**
 * Language support for invariant types
 *
 * Authors: Walter Bright, Sean Kelly, Charlie Curtsinger
 * Date: March 11th, 2008
 * Version: 0.4
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
