/**
 * D symbol demangler
 *
 * Copyright: 2008 The Neptune Project
 */

// Written in the D programming language.

/*
 * Placed into the Public Domain.
 */

/* NOTE: This file has been patched from the original DMD distribution to
   work with the GDC compiler.

   Modified by David Friedman, November 2005
   
   Functions from std.ctype have been incorporated to allow use in the Triton
   runtime library.
   
   Modified by Charlie Curtsinger, February 2008
*/
/****
 * Demangle D mangled names.
 * Macros:
 *	WIKI = Phobos/StdDemangle
 */

/* Authors:
 *	Walter Bright, Digital Mars, www.digitalmars.com
 *	Thomas Kuehne
 *	Frits van Bommel
 */

module std.demangle;

version(unwind)
{

    enum
    {
        _SPC =	8,
        _CTL =	0x20,
        _BLK =	0x40,
        _HEX =	0x80,
        _UC  =	1,
        _LC  =	2,
        _PNC =	0x10,
        _DIG =	4,
        _ALP =	_UC|_LC,
    }

    ubyte _ctype[128] =
    [
        _CTL,_CTL,_CTL,_CTL,_CTL,_CTL,_CTL,_CTL,
        _CTL,_CTL|_SPC,_CTL|_SPC,_CTL|_SPC,_CTL|_SPC,_CTL|_SPC,_CTL,_CTL,
        _CTL,_CTL,_CTL,_CTL,_CTL,_CTL,_CTL,_CTL,
        _CTL,_CTL,_CTL,_CTL,_CTL,_CTL,_CTL,_CTL,
        _SPC|_BLK,_PNC,_PNC,_PNC,_PNC,_PNC,_PNC,_PNC,
        _PNC,_PNC,_PNC,_PNC,_PNC,_PNC,_PNC,_PNC,
        _DIG|_HEX,_DIG|_HEX,_DIG|_HEX,_DIG|_HEX,_DIG|_HEX,
        _DIG|_HEX,_DIG|_HEX,_DIG|_HEX,_DIG|_HEX,_DIG|_HEX,
        _PNC,_PNC,_PNC,_PNC,_PNC,_PNC,
        _PNC,_UC|_HEX,_UC|_HEX,_UC|_HEX,_UC|_HEX,_UC|_HEX,_UC|_HEX,_UC,
        _UC,_UC,_UC,_UC,_UC,_UC,_UC,_UC,
        _UC,_UC,_UC,_UC,_UC,_UC,_UC,_UC,
        _UC,_UC,_UC,_PNC,_PNC,_PNC,_PNC,_PNC,
        _PNC,_LC|_HEX,_LC|_HEX,_LC|_HEX,_LC|_HEX,_LC|_HEX,_LC|_HEX,_LC,
        _LC,_LC,_LC,_LC,_LC,_LC,_LC,_LC,
        _LC,_LC,_LC,_LC,_LC,_LC,_LC,_LC,
        _LC,_LC,_LC,_PNC,_PNC,_PNC,_PNC,_CTL
    ];

    int isdigit(dchar c)  { return (c <= 0x7F) ? _ctype[c] & (_DIG)      : 0; }
    int isxdigit(dchar c) { return (c <= 0x7F) ? _ctype[c] & (_HEX)      : 0; }

    char[] demangle(char[] name)
    {
        size_t ni = 2;
        char[] delegate() fparseTemplateInstanceName;

        static void error()
        {
            assert(false, "Mangle exception");
        }

        static ubyte ascii2hex(char c)
        {
            if (!isxdigit(c))
                error();
            return cast(ubyte)
                   ( (c >= 'a') ? c - 'a' + 10 :
                     (c >= 'A') ? c - 'A' + 10 :
                     c - '0'
                   );
        }

        size_t parseNumber()
        {
            //writefln("parseNumber() %d", ni);
            size_t result;

            while (ni < name.length && isdigit(name[ni]))
            {
                int i = name[ni] - '0';
                if (result > (size_t.max - i) / 10)
                    error();
                result = result * 10 + i;
                ni++;
            }
            return result;
        }

        char[] parseSymbolName()
        {
            //writefln("parseSymbolName() %d", ni);
            size_t i = parseNumber();
            if (ni + i > name.length)
                error();
            char[] result;
            if (i >= 5 &&
                    name[ni] == '_' &&
                    name[ni + 1] == '_' &&
                    name[ni + 2] == 'T')
            {
                size_t nisave = ni;
                bool err;
                ni += 3;

                result = fparseTemplateInstanceName();
                if (ni != nisave + i)
                    err = true;

                ni = nisave;
                if (err)
                    goto L1;
                goto L2;
            }
    L1:
            result = name[ni .. ni + i];
    L2:
            ni += i;
            return result;
        }

        char[] parseQualifiedName()
        {
            //writefln("parseQualifiedName() %d", ni);
            char[] result;

            while (ni < name.length && isdigit(name[ni]))
            {
                if (result.length)
                    result ~= ".";
                result ~= parseSymbolName();
            }
            return result;
        }

        char[] parseType(char[] identifier = null)
        {
            //writefln("parseType() %d", ni);
            int isdelegate = 0;
            bool hasthisptr = false; /// For function/delegate types: expects a 'this' pointer as last argument
    Lagain:
            if (ni >= name.length)
                error();
            char[] p;
            switch (name[ni++])
            {
            case 'v':
                p = "void";
                goto L1;
            case 'b':
                p = "bool";
                goto L1;
            case 'g':
                p = "byte";
                goto L1;
            case 'h':
                p = "ubyte";
                goto L1;
            case 's':
                p = "short";
                goto L1;
            case 't':
                p = "ushort";
                goto L1;
            case 'i':
                p = "int";
                goto L1;
            case 'k':
                p = "uint";
                goto L1;
            case 'l':
                p = "long";
                goto L1;
            case 'm':
                p = "ulong";
                goto L1;
            case 'f':
                p = "float";
                goto L1;
            case 'd':
                p = "double";
                goto L1;
            case 'e':
                p = "real";
                goto L1;
            case 'o':
                p = "ifloat";
                goto L1;
            case 'p':
                p = "idouble";
                goto L1;
            case 'j':
                p = "ireal";
                goto L1;
            case 'q':
                p = "cfloat";
                goto L1;
            case 'r':
                p = "cdouble";
                goto L1;
            case 'c':
                p = "creal";
                goto L1;
            case 'a':
                p = "char";
                goto L1;
            case 'u':
                p = "wchar";
                goto L1;
            case 'w':
                p = "dchar";
                goto L1;

            case 'A':    // dynamic array
                p = parseType() ~ "[]";
                goto L1;

            case 'P':    // pointer
                p = parseType() ~ "*";
                goto L1;

            case 'G':    // static array
            {
                size_t ns = ni;
                parseNumber();
                size_t ne = ni;
                p = parseType() ~ "[" ~ name[ns .. ne] ~ "]";
                goto L1;
            }

            case 'H':    // associative array
                p = parseType();
                p = parseType() ~ "[" ~ p ~ "]";
                goto L1;

            case 'D':    // delegate
                isdelegate = 1;
                goto Lagain;

            case 'M':
                hasthisptr = true;
                goto Lagain;

            case 'F':    // D function
            case 'U':    // C function
            case 'W':    // Windows function
            case 'V':    // Pascal function
            case 'R':    // C++ function
            {
                char mc = name[ni - 1];
                char[] args;

                while (1)
                {
                    if (ni >= name.length)
                        error();
                    char c = name[ni];
                    if (c == 'Z')
                        break;
                    if (c == 'X')
                    {
                        if (!args.length) error();
                        args ~= " ...";
                        break;
                    }
                    if (args.length)
                        args ~= ", ";
                    switch (c)
                    {
                    case 'J':
                        args ~= "out ";
                        ni++;
                    goto default;

                    case 'K':
                        args ~= "inout ";
                        ni++;
                    goto default;

                    case 'L':
                        args ~= "lazy ";
                        ni++;
                    goto default;

                    default:
                        args ~= parseType();
                        continue;

                    case 'Y':
                        args ~= "...";
                        break;
                    }
                    break;
                }
                if (hasthisptr || isdelegate) {
                    // add implicit 'this'/context pointer
                    if (args.length)
                        args ~= ", ";
                    args ~= "void*";
                }
                ni++;
                if (!isdelegate && identifier.length)
                {
                    switch (mc)
                    {
                    case 'F':
                        p = null;
                        break; // D function
                    case 'U':
                        p = "extern (C) ";
                        break; // C function
                    case 'W':
                        p = "extern (Windows) ";
                        break; // Windows function
                    case 'V':
                        p = "extern (Pascal) ";
                        break; // Pascal function
                    default:
                        assert(0);
                    }
                    p ~= parseType() ~ " " ~ identifier ~ "(" ~ args ~ ")";
                    return p;
                }
                p = parseType() ~
                    (isdelegate ? " delegate(" : " function(") ~
                    args ~
                    ")";
                isdelegate = 0;
                goto L1;
            }

            case 'C':
                p = "class ";
                goto L2;
            case 'S':
                p = "struct ";
                goto L2;
            case 'E':
                p = "enum ";
                goto L2;
            case 'T':
                p = "typedef ";
                goto L2;

    L2:
                p ~= parseQualifiedName();
                goto L1;

    L1:
                if (isdelegate)
                    error();  // 'D' must be followed by function
                if (identifier.length)
                    p ~= " " ~ identifier;
                return p;

            default:
                size_t i = ni - 1;
                ni = name.length;
                p = name[i .. length];
                goto L1;
            }
            assert(0);
        }

        char[] parseTemplateInstanceName()
        {
            auto result = parseSymbolName() ~ "!(";
            int nargs;

            while (1)
            {
                size_t i;

                if (ni >= name.length)
                    error();
                if (nargs && name[ni] != 'Z')
                    result ~= ", ";
                nargs++;
                switch (name[ni++])
                {
                case 'T':
                    result ~= parseType();
                    continue;

                case 'V':

                    void getReal()
                    {
                        real r;
                        ubyte *p = cast(ubyte *)&r;

                        if (ni + real.sizeof * 2 > name.length)
                            error();
                        for (i = 0; i < real.sizeof; i++)
                        {
                            ubyte b;

                            b = cast(ubyte)
                                (
                                    (ascii2hex(name[ni + i * 2]) << 4) +
                                    ascii2hex(name[ni + i * 2 + 1])
                                );
                            p[i] = b;
                        }
                        //result ~= format(r);
                        ni += 10 * 2;
                    }

                    result ~= parseType() ~ " ";
                    if (ni >= name.length)
                        error();
                    switch (name[ni++])
                    {
                    case '0':
                    case '1':
                    case '2':
                    case '3':
                    case '4':
                    case '5':
                    case '6':
                    case '7':
                    case '8':
                    case '9':
                        i = ni - 1;
                        while (ni < name.length && isdigit(name[ni]))
                            ni++;
                        result ~= name[i .. ni];
                        break;

                    case 'N':
                        i = ni;
                        while (ni < name.length && isdigit(name[ni]))
                            ni++;
                        if (i == ni)
                            error();
                        result ~= "-" ~ name[i .. ni];
                        break;

                    case 'n':
                        result ~= "null";
                        break;

                    case 'e':
                        getReal();
                        break;

                    case 'c':
                        getReal();
                        result ~= '+';
                        getReal();
                        result ~= 'i';
                        break;

                    case 'a':
                    case 'w':
                    case 'd':
                    {
                        char m = name[ni - 1];
                        if (m == 'a')
                            m = 'c';
                        size_t n = parseNumber();
                        if (ni >= name.length || name[ni++] != '_' ||
                                ni + n * 2 > name.length)
                            error();
                        result ~= '"';
                        for (i = 0; i < n; i++)
                        {
                            char c;

                            c = (ascii2hex(name[ni + i * 2]) << 4) +
                                ascii2hex(name[ni + i * 2 + 1]);
                            result ~= c;
                        }
                        ni += n * 2;
                        result ~= '"';
                        result ~= m;
                        break;
                    }

                    default:
                        error();
                        break;
                    }
                    continue;

                case 'S':
                    result ~= parseSymbolName();
                    continue;

                case 'Z':
                    break;

                default:
                    error();
                }
                break;
            }
            result ~= ")";
            return result;
        }

        if (name.length < 3 ||
                name[0] != '_' ||
                name[1] != 'D' ||
                !isdigit(name[2]))
        {
            goto Lnot;
        }

        fparseTemplateInstanceName = &parseTemplateInstanceName;

        auto result = parseQualifiedName();
        result = parseType(result);
        while (ni < name.length){
            result ~= " . " ~ parseType(parseQualifiedName());
        }

        if (ni != name.length)
            goto Lnot;
        return result;

    Lnot:
        // Not a recognized D mangled name; so return original
        return name;
    }

}
