#include <iostream>
#include <algorithm>
#include <cuda_runtime.h>

unsigned long long quick_rand64(unsigned long long* state) {
    *state ^= *state << 13;
    *state ^= *state >> 7;
    *state ^= *state << 17;
    return *state;
}

__global__ void kernel_reduce_sum_partial(
        float* dest, const float* src, int n) {

    float local_sum = 0.0f;

    for (int i = 0; i < MY_READPERTHREAD; ++i) {
        size_t target = (size_t)i * gridDim.x * MY_BLOCKDIM
            + blockIdx.x * MY_BLOCKDIM
            + threadIdx.x;
        if (target < n)
            local_sum += src[target];
    }

    __shared__ float buf[MY_BLOCKDIM];
    buf[threadIdx.x] = local_sum;

    for (int i = MY_BLOCKDIM/2; i > 0; i >>= 1) {
        __syncthreads();
        if (threadIdx.x < i)
            buf[threadIdx.x] += buf[threadIdx.x + i];
    }

    if (threadIdx.x == 0)
        dest[blockIdx.x] = buf[0];
}

int main(int argc, const char** argv) {
    if (argc != 2) {
        fprintf(stderr, "Usage: ./prog {n}\n");
        exit(1);
    }

    size_t n;
    if (sscanf(argv[1], "%zu", &n) != 1) {
        fprintf(stderr, "Error: invalid number format [%s]\n", argv[1]);
        exit(1);
    }

    if (n <= 0) {
        fprintf(stderr, "Error: invalid n: [%zu]", n);
        exit(1);
    }

    size_t bytes = n * sizeof(float);

    float *h_a, *h_b;
    h_a = (float*)malloc(bytes);
    h_b = (float*)malloc(bytes);


    static unsigned long long seed = 88172645463325252ULL;
    for (size_t i = 0; i < n; ++i) {
        unsigned long long r = quick_rand64(&seed);

        if ((r % n) < 10000)
            h_a[i] = (float)rand() / (float)RAND_MAX;
        else
            h_a[i] = 0.0f;
    }

    float *d_a, *d_b;
    cudaMalloc(&d_a, bytes);
    cudaMalloc(&d_b, bytes);

    cudaMemcpy(d_a, h_a, bytes, cudaMemcpyHostToDevice);

    size_t read_per_block = (size_t)(MY_BLOCKDIM) * (size_t)(MY_READPERTHREAD);

    {
        size_t rem_data = n;

        do {
            size_t blk_cnt = (rem_data + read_per_block - 1) / read_per_block;
            kernel_reduce_sum_partial<<<blk_cnt, MY_BLOCKDIM>>>(d_b, d_a, rem_data);
            std::swap(d_b, d_a);
            rem_data /= read_per_block;
        } while (rem_data > 1);
    }
    
    cudaMemcpy(h_b, d_a, sizeof(float), cudaMemcpyDeviceToHost);

    float sum_ans = 0.0;
    float sum_res = 0.0;

    for (int i = 0; i < n; ++i) sum_ans += h_a[i];
    sum_res = h_b[0];
    
    if (std::abs((double)sum_ans - (double)sum_res) > 0.000001 * (double)n) {
        fprintf(stderr, "Validation Failed, ans:[%f] res:[%f]\n", sum_ans, sum_res);
        exit(1);
    }

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    double mili = 0.0;

    const int iter_cnt = 10;
    for (int iter = 0; iter < iter_cnt; ++iter) {

        size_t rem_data = n;
        cudaEventRecord(start);
        
        do {
            size_t blk_cnt = (rem_data + read_per_block - 1) / read_per_block;
            kernel_reduce_sum_partial<<<blk_cnt, MY_BLOCKDIM>>>(d_b, d_a, rem_data);
            std::swap(d_a, d_b);
            rem_data /= read_per_block;
        } while (rem_data > 1);

        cudaEventRecord(stop);

        cudaEventSynchronize(stop);

        float mili_sec = 0.0f;
        cudaEventElapsedTime(&mili_sec, start, stop);
        mili += mili_sec;
    }

    size_t flop = n * (size_t)iter_cnt;
    double flops = (double)flop * 1000.0 / mili;
    printf("%.6f %.6f\n", flops, mili);

    cudaFree(d_a);
    cudaFree(d_b);
    free(h_a);
    free(h_b);
            
    return 0;
}

