extern void mapPages(uint64_t* L4, addr64_t vAddr, addr64_t pAddr);
extern int map(uint64_t* L4, addr64_t vAddr);
extern void memcopy(void* src, void* dest, uint32_t length);
extern uint64_t* pageDir();
extern uint64_t* morecore();
extern uint32_t nextPage;
