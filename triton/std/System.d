/**
 * Static System class used to access basic system components
 * i.e. standard i/o, filesystem(s), etc...
 *
 * Authors: Charlie Curtsinger
 * Date: November 5th, 2007
 * Version: 0.2a
 */
 
module std.System;

import std.io.InputStream;
import std.io.OutputStream;

class System
{
    private static InputStream stdin = null;
    private static OutputStream stdout = null;
    private static OutputStream stderr = null;
    
    public static InputStream input()
    in
    {
        assert(stdin !is null, "Attempted to use null input stream");
    }
    body
    {
        return stdin;
    }
    
    public static OutputStream output()
    in
    {
        assert(stdout !is null, "Attempted to use null output stream");
    }
    body
    {
        return stdout;
    }
    
    public static OutputStream error()
    in
    {
        assert(stderr !is null, "Attempted to use null error stream");
    }
    body
    {
        return stderr;
    }
    
    public static void setInput(InputStream stdin)
    {
        this.stdin = stdin;
    }
    
    public static void setOutput(OutputStream stdout)
    {
        this.stdout = stdout;
    }
    
    public static void setError(OutputStream stderr)
    {
        this.stderr = stderr;
    }
}
