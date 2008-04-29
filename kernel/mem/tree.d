/**
 * Virtual memory heap allocator
 *
 * Authors: Maxwell Collins, Charlie Curtsinger
 * Date: March 1st, 2008
 * Version: 0.3
 *
 * Copyright: 2008 Maxwell Collins, Charlie Curtsinger
 */

module kernel.mem.tree;

import std.stdio;

const void* MEM_MAX = cast(void*)0xFFFFFFFFFFFFFFFF;

const size_t MINIMUM_BLOCK_SIZE = Block.sizeof;

struct TreeAllocator
{
    private void* heap_start;
    private void* heap_end;
    private void* memory_limit;
    
    Block* last_block;
    
    BlockTree free_tree;

    public static TreeAllocator opCall(ulong heap_start, void* memory_limit = MEM_MAX)
    {
        TreeAllocator t;
        
        t.heap_start = cast(void*)heap_start;
        t.heap_end = cast(void*)heap_start;
        t.memory_limit = memory_limit;
        
        t.last_block = null;
        
        t.free_tree = BlockTree();
        
        return t;
    }
    
    public void* start()
    {
        return heap_start;
    }
    
    public void* end()
    {
        return heap_end;
    }

    public void* allocate(size_t size)
    {
        if(MINIMUM_BLOCK_SIZE - Header.sizeof > size)
            size = MINIMUM_BLOCK_SIZE - Header.sizeof;

        Block* best_fit = free_tree.bestFit(size);

        if(best_fit !is null)
        {
            size_t needed_space = size + Header.sizeof;

            if(best_fit.size - needed_space > MINIMUM_BLOCK_SIZE)
            {
                // Resize the block and create a new allocated block at the end

                best_fit.size = best_fit.size - needed_space;
                
                Block* new_block = cast(Block*)best_fit.next;
                *new_block = Block(cast(Block*)best_fit, size, false);

                // Fix references in the linked list of blocks
                new_block.next.previous = new_block;

                // Fix references in the free tree
                free_tree.remove(best_fit);
                free_tree.insert(best_fit);

                return new_block.data;
            }
            else
            {
                // Allocate the block
                free_tree.remove(best_fit);
                best_fit.free = false;
                return best_fit.data;
            }
        }
       else
        {
            // Check that there's enough room
            if(cast(ulong)heap_end + size + Header.sizeof < cast(ulong)memory_limit) {

                //system.term.printf("here: %x\n", last_block);
                Block* new_block = cast(Block*)heap_end;
                *new_block = Block(last_block, size, false);
                //system.term.printf("here3: %x\n", new_block.header.previous_block);

                last_block = new_block;
                heap_end = new_block.next;

                return new_block.data;
            }
            else {
                return null;
            }
        }
    }
    
    void free(void* ptr)
    {
        // We get the address of the data section,
        // need to find the address of the actual block
        char* data_section = cast(char*)(ptr);
        char* block_addr = data_section - Header.sizeof;
        
        Block* freed_block = cast(Block*)(block_addr);

        Block* prev = freed_block.previous;
        Block* next = freed_block.next;

        // Merge with the previous block
        if(prev !is null && prev.free) {
            Block* prev_free = cast(Block*)(prev);

            free_tree.remove(prev_free);

            if(next != heap_end) {
                next.previous = cast(Block*)prev_free;
            }

            prev_free.size = prev_free.size + freed_block.size + Header.sizeof;
            freed_block = prev_free;
        }
        else {
            // Free the block!
            freed_block.free = true;
        }

        // Merge with the next block
        if(next == heap_end) {
            heap_end = freed_block;
        }
        else {
            if(next != heap_end && next.free()) {
                Block *next_free = cast(Block*)(next);

                free_tree.remove(next_free);

                if(next_free.next != heap_end) {
                    next_free.next.previous = cast(Block*)freed_block;
                }

                freed_block.size = freed_block.size + next_free.size + Header.sizeof;
            }

            free_tree.insert(freed_block);
        }
    }

    void debugDump(bool show_free_tree = false)
    {
        Block *cur_block = cast(Block*)(heap_start);
        writefln("Note: block headers are size %#X", Header.sizeof);

        writefln("Heap starts at %#X", cast(ulong)heap_start);

        writeln("address             state      size      previous");

        while(cur_block < heap_end)
        {
            char[] free = cur_block.free ? "free     " : "allocated";
            char *addr = cast(char*)(cur_block);
            size_t size = cur_block.size;

            writefln("%p, %s, %06#X, %p", cast(ulong)addr, free, cast(ulong)size, cast(ulong)cur_block.previous);

            cur_block = cur_block.next;
        }

        writefln("Heap ends at %#X", cast(ulong)heap_end);
        
        if(show_free_tree)
        {
            writeln("\nFree Tree:");
            free_tree.debugDump();
        }
    }
}

/**
 * \brief The block header
 *
 * This is placed at the beginning of every block of memory in the heap
 */
struct Header
{
    bool free;
    Block* previous_block;
    size_t size;
    
    public static Header opCall(bool free, Block* previous_block, size_t size)
    {
        Header h;
        h.free = free;
        h.previous_block = previous_block;
        h.size = size;
        
        return h;
    }
}

/**
 * \brief A block of memory on the heap
 *
 * These blocks can either be allocated or free.  The blocks store enough
 * information to determine:
 * - The size of a block
 * - Whether the block is free
 * - The location of the blocks adjacent in memory (to allow merging
 *   of adjacent free blocks)
 */
struct Block
{
    private Header header;
    
    public Block* left;
    public Block* right;
    public Block* parent;
    
    public static Block opCall(Block* previous_block, size_t size, bool free)
    {
        Block b;
        b.header = Header(free, previous_block, size);
        return b;
    }

    /**
     * \brief The block preceding this one in memory
     *
     * Expected to be null if this block is at the start of the heap
     */
    public Block* previous()
    {
        return header.previous_block;
    }
    
    public void previous(Block* p)
    {
        header.previous_block = p;
    }

    /**
     * \brief The block after this one in memory
     *
     * \note This is not garunteed to be within the heap.  It is the
     *       responsibility Heap methods to verify this.
     */
    public Block* next()
    {
        char* this_start = cast(char*)(this);
        char* next_start = this_start + Header.sizeof + header.size;
        
        size_t start = cast(size_t)this;

        return cast(Block*)(start + Header.sizeof + header.size);
    }

    /**
     * \brief A reference to the size of the block
     */
    public size_t size()
    {
        return header.size;
    }
    
    public void size(size_t s)
    {
        header.size = s;
    }

    public bool free()
    {
        return header.free;
    }
    
    public void free(bool f)
    {
        header.free = f;
    }

    /**
     * \brief The start of the allocatable portion of the block
     *
     * This skips past the header to the portion of the block that
     * the user can stick stuff in.
     */
    public void* data()
    {
        char *block_start = cast(char*)(this);

        return cast(void*)(block_start + Header.sizeof);
        
        return cast(void*)(cast(size_t)this + Header.sizeof);
    }

}

struct BlockTree
{
    private Block* root;
    
    public static BlockTree opCall()
    {
        BlockTree t;
        
        t.root = null;
        
        return t;
    }

    public bool empty()
    {
        return root is null;
    }

    public void insert(Block* new_block)
    {
        new_block.left = null;
        new_block.right = null;

        if(root !is null)
        {
            Block *insertion_point = root;

            while(true)
            {
                if(insertion_point.size > new_block.size)
                {
                    if(insertion_point.left !is null)
                    {
                        insertion_point = insertion_point.left;
                    }
                    else
                    {
                        insertion_point.left = new_block;
                        break;
                    }
                }
                else
                {
                    if(insertion_point.right !is null)
                    {
                        insertion_point = insertion_point.right;
                    }
                    else
                    {
                        insertion_point.right = new_block;
                        break;
                    }
                }
            }

            new_block.parent = insertion_point;
        }
        else
        {
            root = new_block;
            new_block.parent = null;
        }
    }
    
    public void remove(Block* deleted_block)
    {
        Block** reference_to_deleted_block = referenceToBlock(deleted_block);

        if(deleted_block.left is null)
        {
            *(reference_to_deleted_block) = deleted_block.right;
            if(deleted_block.right !is null)
            {
                deleted_block.right.parent = deleted_block.parent;
            }
        }
        else if(deleted_block.right is null)
        {
            *(reference_to_deleted_block) = deleted_block.left;
            deleted_block.left.parent = deleted_block.parent;
        }
        else
        {
            Block *s = successor(deleted_block);

            // Splice the successor out of the tree
            s.parent.left = s.right;

            // Move the successor to take deleted_block's place
            s.parent = deleted_block.parent;
            *(reference_to_deleted_block) = s;

            s.left  = deleted_block.left;
            s.right = deleted_block.right;
            s.left.parent = s;
            s.right.parent  = s;
        }
    }
    
    public Block* bestFit(size_t size)
    {
        Block *best_fit = null;
        Block *x = root;

        while(x !is null) {
            if(best_fit !is null && x.size > size) {
                if(best_fit.size > x.size) {
                    best_fit = x;
                }

                x = x.left;
            }
            else {
                x = x.right;
            }
        }

        return best_fit;
    }

    public Block** referenceToBlock(Block* block)
    {
        if(block.parent !is null)
        {
            if(block.parent.left == block)
            {
                return &(block.parent.left);
            }
            else
            {
                return &(block.parent.right);
            }
        }
        else 
        {
            return &root;
        }
    }
    
    public Block* successor(Block* x)
    {
        if(x.right !is null)
        {
            while(x.left !is null)
            {
                x = x.left;
            }
            return x;
        }
        else
        {
            return null;
        }
    }
    
    public void debugDump()
    {
        debugDump(root, 0);
    }

    public void debugDump(Block* node, size_t tab_level)
    {
        for(uint i = 0; i < tab_level; i++) {
            write("  ");
        }

        if(node is null) {
            writeln("null");
        }
        else {
            writefln("%#X: %#X from %#X", cast(ulong)node, cast(ulong)node.size, cast(ulong)node.parent);

            debugDump(node.left, tab_level + 1);
            debugDump(node.right, tab_level + 1);
        }
    }
}
