all: neptune

neptune:
	scons
	
info: build/kernel
	analysis/sizes.py --tree build/kernel

clean: cleanall

cleanall:
	scons -c

run:
	qemu -m 512 -cdrom neptune.iso -boot d -net nic,vlan=0 -net user,vlan=0  -localtime
