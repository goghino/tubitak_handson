CUDA_ROOT=/opt/cuda
MPICC=/home/jkardos/openmpi-1.8.1/install/bin/mpicc

all: mpi_cuda_sendrecv mpi_cuda_sendrecv_sol

mpi_cuda_sendrecv: mpi_cuda_sendrecv.o pattern2d.o
	$(MPICC) mpi_cuda_sendrecv.o pattern2d.o -o $@ -L$(CUDA_ROOT)/lib64 -lcudart

mpi_cuda_sendrecv.o: mpi_cuda_sendrecv.c
	$(MPICC) -g -std=c99 -I$(CUDA_ROOT)/include -c $< -o $@


mpi_cuda_sendrecv_sol: mpi_cuda_sendrecv_sol.o pattern2d.o
	$(MPICC) mpi_cuda_sendrecv_sol.o pattern2d.o -o $@ -L$(CUDA_ROOT)/lib64 -lcudart

mpi_cuda_sendrecv_sol.o: mpi_cuda_sendrecv_sol.c
	$(MPICC) -g -std=c99 -I$(CUDA_ROOT)/include -c $< -o $@


pattern2d.o: pattern2d.cu
	nvcc -g -c $< -o $@

run:
	/home/jkardos/openmpi-1.8.1/install/bin/mpirun -np 2 ./mpi_cuda_sendrecv 1024 2
	/home/jkardos/openmpi-1.8.1/install/bin/mpirun -np 2 ./mpi_cuda_sendrecv_sol 1024 2

clean:
	rm -rf *.o mpi_cuda_sendrecv mpi_cuda_sendrecv_sol

