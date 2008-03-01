/**
 * Functions for constructing, testing, and destructing modules
 *
 * Based on module unit test support in Phobos (Walter Bright)
 *
 * Authors: Charlie Curtsinger, Walter Bright
 * Date: March 1st, 2008
 * Version: 0.3
 *
 * Copyright: 2004-2008 Digital Mars, www.digitalmars.com
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

module modinit;

import std.stdio;

/**
 * Represents one ModuleInfo object created by
 * a constructor function
 */
struct ModuleReference
{
	ModuleReference* next;
	ModuleInfo mod;
}

enum
{   
	MIctorstart = 1,	// we've started constructing it
    MIctordone = 2,	// finished construction
    MIstandalone = 4,	// module ctor does not depend on other module
    // ctors being done first
}

/// Linked list of ModuleInfo objects populated by constructors
extern (C) ModuleReference* _Dmodule_ref;	// start of linked list

/**
 * Get the head pointer for the ModuleInfo linked list
 */
ModuleReference* get_module_ref()
{
	return _Dmodule_ref;
}

/**
 * Call module constructors
 */
void _moduleCtor()
{
	ModuleReference* modules = _Dmodule_ref;
	
	while(modules !is null)
	{
		ModuleInfo m = modules.mod;
		
		_moduleCtor2(m);
		
		modules = modules.next;
	}
}

/**
 * Run module unit tests
 */
void _moduleUnitTests()
{
	ModuleReference* modules = _Dmodule_ref;
	
	while(modules !is null)
	{
		ModuleInfo m = modules.mod;
		
		if(m.unitTest)
		{
			m.unitTest();
		}
		
		modules = modules.next;
	}
}

/**
 * Run the constructor for a particular module and
 * its imported modules.
 *
 * Params:
 *  m = module to run constructor(s) for
 */
void _moduleCtor2(ModuleInfo m)
{
	if (!m)
	{
		return;
	}

	if (m.flags & MIctordone)
	{
		return;
	}

	if (m.ctor || m.dtor)
	{
		if (m.flags & MIctorstart)
		{
			if (m.flags & MIstandalone)
			{
				return;
			}
			
			//throw new ModuleCtorError(m);
			//assert(false, "Module constructor error");
		}

		m.flags |= MIctorstart;
		
		foreach(ModuleInfo imported; m.importedModules)
		{
			_moduleCtor2(imported);
		}
		
		if (m.ctor)
		{
			(*m.ctor)();
		}
		
		m.flags &= ~MIctorstart;
		m.flags |= MIctordone;
	}
	else
	{
		m.flags |= MIctordone;
		
		foreach(ModuleInfo imported; m.importedModules)
		{
			_moduleCtor2(imported);
		}
	}
}

/**
 * Run module destructors
 *
 * UNTESTED
 */
void _moduleDtor()
{
    ModuleReference* modules = _Dmodule_ref;
	
	while(modules !is null)
	{
		ModuleInfo m = modules.mod;
		
		if (m.dtor)
        {
            (*m.dtor)();
        }
		
		modules = modules.next;
	}
}
