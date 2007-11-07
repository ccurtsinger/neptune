/**
 * Static System class used to access basic system components
 * i.e. standard i/o, filesystem(s), etc...
 *
 * Authors: Charlie Curtsinger
 * Date: November 5th, 2007
 * Version: 0.2a
 */
 
module std.System;

import std.io.CharStream;

class System
{
    private static CharInputStream stdin = null;
    private static CharOutputStream stdout = null;
    private static CharOutputStream stderr = null;
    
    public static CharInputStream input()
    in
    {
        assert(stdin !is null, "Attempted to use null input stream");
    }
    body
    {
        return stdin;
    }
    
    public static CharOutputStream output()
    in
    {
        assert(stdout !is null, "Attempted to use null output stream");
    }
    body
    {
        return stdout;
    }
    
    public static CharOutputStream error()
    in
    {
        assert(stderr !is null, "Attempted to use null error stream");
    }
    body
    {
        return stderr;
    }
    
    public static void setInput(CharInputStream stdin)
    {
        this.stdin = stdin;
    }
    
    public static void setOutput(CharOutputStream stdout)
    {
        this.stdout = stdout;
    }
    
    public static void setError(CharOutputStream stderr)
    {
        this.stderr = stderr;
    }
}
