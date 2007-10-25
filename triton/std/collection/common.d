module std.collection.common;

abstract class Collection(T)
{
	/**
	 * Return true if the collection contains t
	 */
	abstract bool contains(T t);
	
	/**
	 * Add t to the collection
	 */
	abstract void add(T t);
	
	/**
	 * Remove an element matching t from the collection and return it
	 */
	abstract T remove(T t);
	
	/**
	 * Return the number of elements in the collection
	 */
	abstract size_t size();
}

abstract class IndexedCollection(T) : Collection!(T)
{
	/**
	 * Add t so it resides at `index`
	 */
	abstract void add(size_t index, T t);
	
	/**
	 * Get the element at `index`
	 */
	abstract T get(size_t index);
	
	/**
	 * Remove the element at `index` and return it
	 */
	abstract T remove(size_t index);
}


