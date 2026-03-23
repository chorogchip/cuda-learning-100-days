#include <iostream>
#include <cmath>
#include <cuda_runtime.h>

unsigned long long my_rand64();
float* gen_sparse_buf(size_t n);

static struct Data {
    size_t n;
} data_;

size_t get_flop() {

}

void init_problem(size_t n) {
    data_.n = n;
}

void clear_problem() {

}

bool validate_problem() {

}

void exec_problem() {

}

