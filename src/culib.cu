
static unsigned long long rand_state_ = 88172645463325252ULL;

unsigned long long my_rand64() {
    rand_state_ ^= rand_state_ << 13;
    rand_state_ ^= rand_state_ >> 7;
    rand_state_ ^= rand_state_ << 17;
    return rand_state_;
}

float* gen_sparse_buf(size_t n) {
    float* ret = (float*)malloc(n * sizeof(float));

    for (size_t i = 0; i < n; ++i) {
        unsigned long long r = my_rand64();

        if (r % n < 10000)
            ret[i] = (float)rand() / (float)RAND_MAX;
        else
            ret[i] = 0.0f;
    }

    return ret;
}

