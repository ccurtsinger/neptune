/**
 * Functions for constructing, testing, and destructing modules
 *
 * Authors: Charlie Curtsinger
 * Date: October 30th, 2007
 * Version: 0.1a
 */

module std.modinit;

import std.stdio;
import std.stdlib;

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
			write("  ");
			write(m.name);
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
			assert(false, "Module constructor error");
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
