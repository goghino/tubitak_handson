/*
 *
 * Copyright (c) 2014 Juraj Kardos
 *
 * This software is provided 'as-is', without any express or implied warranty.
 * In no event will the authors be held liable for any damages arising 
 * from the use of this software.
 * Permission is granted to anyone to use this software for any purpose, 
 * including commercial applications, and to alter it and redistribute it freely,
 * without any restrictons.
 */

#include <stdio.h>

#include <cuda_runtime.h>

#include "nvToolsExt.h"

#define n (16*1014*1024)

__global__ void increment_kernel(int *g_data, int inc_value)
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;

    if(idx > n/4)
      return;

    //to be more computational intensive, repeat same task multiple times
    for(int i=0; i<30; i++)
        g_data[idx] = g_data[idx] + inc_value;
}

#define checkCudaErrors(cuda_call)  \
{  \
        cudaError_t err = (cuda_call);  \
            if (err!=cudaSuccess){  \
             printf("\033[31mERROR: %s\n\033[0m", cudaGetErrorString(err));  \
             exit(1);  \
            }  \
}


int main(int argc, char *argv[])
{
    int nbytes = n * sizeof(int);
    int value = 26;

    // allocate pinned host memory
    int *a = 0;
    //TODO
    //allocate pinned memory to hold our input data
    //...
    //memset(a, 0, nbytes);

    // allocate device memory
    int *d_a=0;
    //TODO
    //Allocate memory on device to hold input data
    //...
    //checkCudaErrors(cudaMemset(d_a, 255, nbytes));

    //TODO
    // Set kernel launch configuration
    // For each input element we want one GPU thread
    dim3 threads = dim3(1,1,1);
    dim3 blocks  = dim3(1,1,1);

    // create cuda event handles
    cudaEvent_t start, stop;
    checkCudaErrors(cudaEventCreate(&start));
    checkCudaErrors(cudaEventCreate(&stop));
    checkCudaErrors(cudaDeviceSynchronize());

    //multi GPU related set-up

    //TODO
    //get count of devices for the multi GPU kernel
    int ndevices = 0;

    int *d_as[ndevices];
    cudaEvent_t stop_ev[ndevices];
    // create cuda streams for each device
    cudaStream_t stream_multi[4];

    //TODO
    //set up computation for multi GPU
    for(int i=0; i<ndevices; i++)
    {
        //TODO
        //select current device

        //TODO
        //create cuda stream for current device

        //TODO
        // allocate device memory to hold curent device's part of input data
        // ...
        //checkCudaErrors(cudaMemset(d_as[i], 255, nbytes/4));

	    //create events
	    cudaEventCreate(&stop_ev[i]);
    }

    cudaSetDevice(0);
//------------------------------------------------------------------------------
// 1. We run single kernel with blocking memory copies

    cudaEventRecord(start, 0);
    cudaMemcpy(d_a, a, nbytes, cudaMemcpyHostToDevice);
    increment_kernel<<<blocks, threads, 0, 0>>>(d_a, value);
    cudaEventRecord(stop, 0);

    // have CPU do some work while waiting for stage 1 to finish
    unsigned long int counter=0;

    nvtxRangePushA("CPU Compute");
    while (cudaEventQuery(stop) == cudaErrorNotReady)
    {
        counter++;
    }
    nvtxRangePop();
    cudaMemcpy(a, d_a, nbytes, cudaMemcpyDeviceToHost);
    cudaEventRecord(stop, 0);
    cudaDeviceSynchronize();

    float gpu_time_block = 0.0f;
    checkCudaErrors(cudaEventElapsedTime(&gpu_time_block, start, stop));
    printf("One big kernel compute time (blocking): %fms\n", gpu_time_block);

//------------------------------------------------------------------------------
// 2. We run single kernel with non-blocking memory copies

    cudaEventRecord(start, 0);
    //TODO
    // asynchronously copy data, run kernel and copy back
    cudaEventRecord(stop, 0);

    // have CPU do some work while waiting for stage 1 to finish
    counter=0;

    nvtxRangePushA("CPU Compute");
    while (cudaEventQuery(stop) == cudaErrorNotReady)
    {
        counter++;
    }
    nvtxRangePop();

    float gpu_time = 0.0f;
    checkCudaErrors(cudaEventElapsedTime(&gpu_time, start, stop));
    printf("One big kernel compute time (async): %fms\n", gpu_time);

//------------------------------------------------------------------------------
// 3. Run kernel on partitioned data multiple times, overlap computation and communication

    // set kernel launch configuration
    threads = dim3(512, 1, 1);
    blocks  = dim3(n / 4 / threads.x, 1, 1);

    // create cuda streams
    cudaStream_t stream[4];
    //TODO
    //create 4 streams that we will use for submitting workload to GPU

    checkCudaErrors(cudaDeviceSynchronize());

    int offset = n/4;

    cudaEventRecord(start, stream[0]);

    //TODO
    // asynchronously copy data, run kernel and copy back
    // Submit cuda operation chain H2D - kernel - D2H into different streams
    // Each kernel computes only its own partition of data!    

    cudaEventRecord(stop, stream[2]);

    // have CPU do some work while waiting for stage 1 to finish
    counter=0;

    nvtxRangePushA("CPU Compute");
    while (cudaEventQuery(stop) == cudaErrorNotReady)
    {
        counter++;
    }
    nvtxRangePop();

    float gpu_time1 = 0.0f;
    checkCudaErrors(cudaEventElapsedTime(&gpu_time1, start, stop));
    printf("Many small kernels compute time (single GPU): %fms\n", gpu_time1);
    printf("Speedup is %f\n", gpu_time/gpu_time1);

//------------------------------------------------------------------------------
// 4. We run each stream from previous case on different GPUs  

    printf("Found %d CUDA capable devices\n", ndevices);    

    cudaSetDevice(0);
    cudaEventRecord(start, stream_multi[0]);

    //submit work to GPU devices
    for(int i=0; i<ndevices; i++)
    {    
        //TODO
        //set device and submit its H2D-kernel-D2H compute chain

        cudaEventRecord(stop_ev[i], stream_multi[i]);
    }

    // have CPU do some work while waiting for stage 1 to finish
    counter=0;

    nvtxRangePushA("CPU Compute");
    while (cudaEventQuery(stop_ev[0]) == cudaErrorNotReady ||
           cudaEventQuery(stop_ev[1]) == cudaErrorNotReady ||
           cudaEventQuery(stop_ev[2]) == cudaErrorNotReady ||
           cudaEventQuery(stop_ev[3]) == cudaErrorNotReady )  
    {
        counter++;
    }

    /*
    for(int i=0; i<ndevices; i++)
    {
      cudaEventSynchronize(stop_ev[i]);  
    }
    */

    //cudaDeviceSynchronize();

    nvtxRangePop();

    float gpu_time2 = 0.0f;
    cudaSetDevice(0);
    checkCudaErrors(cudaEventElapsedTime(&gpu_time2, start, stop_ev[0]));
    printf("Many small kernels compute time (multi GPU): %fms\n", gpu_time2);
    printf("Speedup is %f\n", gpu_time/gpu_time2);

//------------------------------------------------------------------------------
    // release resources
    cudaSetDevice(0);
    checkCudaErrors(cudaEventDestroy(start));
    checkCudaErrors(cudaEventDestroy(stop));
    checkCudaErrors(cudaEventDestroy(stop_ev[0]));
    checkCudaErrors(cudaEventDestroy(stop_ev[1]));
    checkCudaErrors(cudaEventDestroy(stop_ev[2]));
    checkCudaErrors(cudaEventDestroy(stop_ev[3]));
    checkCudaErrors(cudaFreeHost(a));
    checkCudaErrors(cudaFree(d_a));
    cudaStreamDestroy(stream[0]);
    cudaStreamDestroy(stream[1]);
    cudaStreamDestroy(stream[2]);
    cudaStreamDestroy(stream[3]);

    //free memory
    for(int i=0; i<ndevices; i++)
    {
        cudaSetDevice(i);
        cudaFree(d_as[i]);
        cudaStreamDestroy(stream_multi[i]);
    }

    // flush all profile data
    cudaDeviceReset();

}
