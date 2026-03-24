#include <iostream>
#include <cmath>
#include <cuda_runtime.h>

unsigned long long my_rand64();
float* gen_sparse_buf(size_t n);

// MY_BLOCKDIM
// MY_RPT: read per thread
#define WARP_P_BLOCK ((MY_BLOCKDIM) >> 5)

__global__ void kernel_prefix(float* dest_blocksums, float* dest_partial, const float* src, size_t n) {
    size_t idx = threadIdx.x + blockIdx.x * blockDim.x;
    int lane = threadIdx.x & 31;
    float val = idx < n ? src[idx] : 0.0f;

    for (int i = 1; i <= 16; i *= 2) {
        float temp = __shfl_up_sync(0xffffffff, val, i);
        if (lane >= i) val += temp;
    }

    __shared__ float mem_block[WARP_P_BLOCK];
    int warp = threadIdx.x >> 5;
    if (lane == 31) mem_block[warp] = val;
    __syncthreads();

    if (warp == 0) {
        float val2 = lane < WARP_P_BLOCK ? mem_block[lane] : 0.0f;
        for (int i = 1; i <= 16; i *= 2) {
            float temp = __shfl_up_sync(0xffffffff, val2, i);
            if (lane >= i) val2 += temp;
        }

        if (lane == 31) dest_blocksums[blockIdx.x] = val2;
        val2 = __shfl_up_sync(0xffffffff, val2, 1);
        if (lane == 0) val2 = 0.0f;
        if (lane < WARP_P_BLOCK) mem_block[lane] = val2;
    }
    __syncthreads();
    
    val += mem_block[warp];

    if (idx < n) dest_partial[idx] = val;
}

__global__ void kernel_sum(float* buf, const float* src_block, size_t n) {
    size_t idx = threadIdx.x + blockIdx.x * blockDim.x;
    if (idx < n && blockIdx.x > 0) {
        buf[idx] += src_block[blockIdx.x - 1];
    }
}

static struct Data {
    size_t n;
    float *h_s, *h_d, *d_s, *d_d, *d_b;
} data_;

size_t get_flop() {
    return data_.n;
}

void init_problem(size_t n) {
    size_t bytes = n * sizeof(float);

    data_.n = n;
    data_.h_s = gen_sparse_buf(n);
    data_.h_d = (float*)malloc(bytes);
    cudaMalloc(&data_.d_s, bytes*2);
    cudaMalloc(&data_.d_d, bytes*2);
    cudaMalloc(&data_.d_b, bytes*2);

    cudaMemcpy(data_.d_s, data_.h_s, bytes, cudaMemcpyHostToDevice);
}

void clear_problem() {
    cudaFree(data_.d_s);
    cudaFree(data_.d_d);
    cudaFree(data_.d_b);
    free(data_.h_s);
    free(data_.h_d);
}

bool validate_problem() {
    cudaMemcpy(data_.h_d, data_.d_d, data_.n * sizeof(float), cudaMemcpyDeviceToHost);
    float sum = data_.h_s[0];
    for (size_t i = 1; i < data_.n; ++i) {
        sum += data_.h_s[i];
        if (std::abs(sum - data_.h_d[i]) > 0.0001f * (float)data_.n)
            return false;
    }
    return true;
}

void exec_problem_inner(float* dest_block, float* dest, float* src, size_t n) {
    size_t grid_dim = (n + MY_BLOCKDIM - 1) / MY_BLOCKDIM;
    
    kernel_prefix<<<grid_dim, MY_BLOCKDIM>>>(dest_block, dest, src, n);
    
    if (grid_dim <= 1) return;

    exec_problem_inner(src + n, dest + n, dest_block, grid_dim);

    kernel_sum<<<(n + MY_BLOCKDIM - 1) / MY_BLOCKDIM, MY_BLOCKDIM>>>(dest, dest + n, n);
}

void exec_problem() {
    exec_problem_inner(data_.d_b, data_.d_d, data_.d_s, data_.n);
}

