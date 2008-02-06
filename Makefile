all:
	bash ./scons.sh

cleanall:
	bash ./scons.sh -c

run:
	qemu-system-x86_64 -L . -m 512 -cdrom neptune.iso -boot d -net nic,vlan=0 -net user,vlan=0  -localtime
