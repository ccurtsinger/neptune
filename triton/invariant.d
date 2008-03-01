/**
 * Language support for invariant types
 *
 * Authors: Walter Bright, Sean Kelly, Charlie Curtsinger
 * Date: March 1st, 2008
 * Version: 0.3
 */

/*
 * Placed into the Public Domain
 * written by Walter Bright
 * www.digitalmars.com
 */

/**
 * Does invariant things.  Need to figure this out.
 */
void _d_invariant(Object o)
{
    ClassInfo c;

    //writefln("__d_invariant(%016#X)", cast(ulong)o);

    // BUG: needs to be filename/line of caller, not library routine
    assert(o !is null);	// just do null check, not invariant check

    c = o.classinfo;

    do
    {
        if (c.classInvariant)
        {
            (*c.classInvariant)(o);
        }

        c = c.base;
    } while (c);
}
