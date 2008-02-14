all:
	bash ./scons.sh neptune.iso

cleanall:
	bash ./scons.sh -c neptune.iso

run:
	bash ./run.sh
