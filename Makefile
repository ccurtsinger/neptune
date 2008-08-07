all:
	scons

info: all
	analysis/sizes.py --tree build/x86_64/kernel

clean: cleanall

cleanall:
	scons -c

run:
	qemu-system-x86_64 -m 512 -cdrom neptune.iso -boot d -net nic,vlan=0 -net user,vlan=0  -localtime
