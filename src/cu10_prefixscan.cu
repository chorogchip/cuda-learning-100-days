#include <iostream>
#include <cmath>
#include <cuda_runtime.h>

unsigned long long my_rand64();
float* gen_sparse_buf(size_t n);

__global__ void kernel_prefix(float* dest, const float* src, size_t n) {

}

static struct Data {
    size_t n;
    float *h_s, *h_d, *d_s, *d_d;
} data_;

size_t get_flop() {
    return data_.n;
}

void init_problem(size_t n) {
    size_t bytes = n * sizeof(float);

    data_.n = n;
    data_.h_s = gen_sparse_buf(n);
    data_.h_d = (float*)malloc(bytes);
    cudaMalloc(&data_.d_s, bytes);
    cudaMalloc(&data_.d_d, bytes);

    cudaMemcpy(d_s, h_s, bytes, cudaMemcpyHostToDevice);
}

void clear_problem() {
    cudaFree(data_.d_s);
    free(data_.h_s);
    free(data_.h_d);
    cudaFree(data_.d_d);
}

bool validate_problem() {
    cudaMemcpy(data_.h_d, data_.d_d, bytes, cudaMemcpyDeviceToHost);
    float sum = data_.h_s[0];
    for (size_t i = 1; i < n; ++i) {
        sum += data_.h_s[i];
        if (std::abs(sum - data_.h_d[i]) > 0.0001f * (float)data_.n)
            return false;
    }
    return true;
}

void exec_problem() {
    kernel_prefix<<<1,1>>>(data_.d_d, data_.d_s, data_.n);
}

