/**
 * Stack (LIFO) implementations using linked-list and expanding array approaches
 *
 * Authors: Charlie Curtsinger
 * Date: October 31st, 2007
 * Version: 0.1b
 */

module std.collection.Stack;

/**
 * Stack implementation based on a linked list method.
 * Uses n*T.sizeof memory for n elements
 *
 * Params:
 *  T = Element type to store in the stack
 */
class Stack(T)
{
	private T[] data;
	
	/**
	 * Create an empty stack
	 */
	public this()
	{
		data.length = 0;
	}
	
	/**
	 * Free all used memory by emptying the stack
	 */
	public ~this()
	{
		delete data;
	}
	
	/**
	 * Get the size of the stack
	 *
	 * Returns: The number of elements in the stack
	 */
	public size_t size()
	{
		return data.length;
	}
	
	/**
	 * Push an element onto the stack
	 *
	 * Params:
	 *  t = Element to push
	 */
	public void push(T t)
	{
		data.length = data.length + 1;
		data[length-1] = t;
	}
	
	/**
	 * Pop an element off the top of the stack
	 *
	 * Returns: The top element on the stack
	 */
	public T pop()
	in
	{
		assert(data.length > 0, "Stack empty - unable to execute pop()");
	}
	body
	{
		T t = data[length-1];
		data.length = data.length - 1;
		
		return t;
	}
}
