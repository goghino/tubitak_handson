#we need cuda aware build of MPI library
cc := /home/jkardos/openmpi-1.8.1/install/bin/mpicc
FLAGS := -g
INCLUDE := -I/opt/cuda/include
LDFLAGS := -L/opt/cuda/lib64
CFLAGS := -std=c99 -Wall
 

# Target rules
all: build

build: cudaMPI

cudaMPI: cudaAwareMPI.c
	$(cc) $(CFLAGS) $(INCLUDE) $(FLAGS) $(LDFLAGS) -o $@ $< -lcudart

run: build
	/home/jkardos/openmpi-1.8.1/install/bin/mpirun -np 4 ./cudaMPI

clean:
	rm -f cudaMPI

