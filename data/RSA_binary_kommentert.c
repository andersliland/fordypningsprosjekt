#include <stdio.h>


//Finds the most significant bit of the input value
unsigned long long int getmsb(unsigned long long int x) {
    unsigned long long int r = 0;
    if (x < 1) return 0;

    while (x >>= 1) r++;
    return r;
}



unsigned long long int blakley(unsigned long long int a,
unsigned long long int b, unsigned long long int n) {

    unsigned long long int num_bit_a = getmsb(a) + 1;
    unsigned long long int num_bit_b = getmsb(b) + 1;

    unsigned int k = num_bit_a;

    //Checks which of the variables a and b has the MSB
    if (num_bit_a < num_bit_b) {
        unsigned long long int temp = a;
        a = b;
        b = temp;
        k = num_bit_b;

    }
    unsigned long long int R = 0;
    unsigned int i = 0;



    //Operation the is equivalent to modulus
    for (i = 0; i <= (k - 1); i++) {

        R = 2 * R + ((a >> (k - 1 - i)) & 1) * b;

        if (R >= n)
            R = R - n;
        if (R >= n)
            R = R - n;


    }
    return R;
}


int main() {


    //message, result, and keys for a 32-bit blakley

    unsigned long long int result = 0x79114D01;
    unsigned long long int M = 0x0AAABBBB;
    unsigned long long int n = 0x819DC6B2;
    unsigned long long int e = 0x70DF64F3;
    unsigned long long int C;

    //number of bits
    unsigned int k = getmsb(e) + 1;
    printf("Binary k = %i \n", k);

    /*Checks the value of bit k-1 in key e,
    and gives C it's corresponding value*/

    if (e & (1 << k - 1)) {
        C = M;
    } else {
        C = 1;
    }

    printf("C initial = %i \n", C);


    /*Checks bits in e, and gives C the correct value,
    then calls the blakley function */
    for (int i = k - 2; i >= 0; i--) {
        C = blakley(C, C, n);
        if (e & (1 << i)) { C = blakley(C, M, n); }

    }

    printf("\n\n");
    printf("result =  %x \n", result);
    printf("     C =  %x \n", C);


    return 0;

}

