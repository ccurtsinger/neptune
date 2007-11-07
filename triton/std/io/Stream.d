

module std.io.Stream;

interface InputStream(T)
{
	public T read();
	
	public T[] read(size_t size, T[] buf = null);
}

interface OutputStream(T)
{
	public OutputStream write(T t);
	
	public OutputStream write(T[] t);
}
