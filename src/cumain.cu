#include <iostream>
#include <cuda_runtime.h>

void init_problem(size_t n);
void clear_problem();
size_t get_flop();
bool validate_problem();
void exec_problem();

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

    init_problem(n);

    exec_problem();

    if (!validate_problem()) {
        fprintf(stderr, "Validation Failed\n");
        clear_problem();
        exit(1);
    }

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    double mili = 0.0;

    const int iter_cnt = 10;
    for (int iter = 0; iter < iter_cnt; ++iter) {

        cudaEventRecord(start);
        
        exec_problem();

        cudaEventRecord(stop);

        cudaEventSynchronize(stop);

        float mili_sec = 0.0f;
        cudaEventElapsedTime(&mili_sec, start, stop);
        mili += mili_sec;
    }

    size_t flop = get_flop() * (size_t)iter_cnt;
    double flops = (double)flop * 1000.0 / mili;
    printf("%.6f %.6f\n", flops, mili);

    clear_problem();
            
    return 0;
}

