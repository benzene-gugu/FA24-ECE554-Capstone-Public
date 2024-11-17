#include<stdio.h>
#include<math.h>
#define PI 3.14159265
int n;

int sqrt(int x)
{
    // Base cases
    if (x == 0 || x == 1)
        return x;
 
    // Starting from 1, try all numbers until
    // i*i is greater than or equal to x.
    int i = 1, result = 1;
    while (result <= x) {
        i++;
        result = i * i;
    }
    return i - 1;
}


int main(int argc, char **argv) {
    double realOut[n][n];
    double imagOut[n][n];
    double amplitudeOut[n][n];
 
    int height = n;
    int width = n;
    int yWave;
    int xWave;
    int ySpace;
    int xSpace;
    int i, j;
    double inputData[n][n];
 
    printf("Enter the size: ");
    scanf("%d", &n);
 
    printf("Enter the 2D elements ");
    for (i = 0; i < n; i++)
        for (j = 0; j < n; j++)
            scanf("%lf", &inputData[i][j]);
 
 
    // Two outer loops iterate on output data.
    for (yWave = 0; yWave < height; yWave++) {
        for (xWave = 0; xWave < width; xWave++) {
            // Two inner loops iterate on input data.
            for (ySpace = 0; ySpace < height; ySpace++) {
                for (xSpace = 0; xSpace < width; xSpace++) {
                    // Compute real, imag, and ampltude.
                    realOut[yWave][xWave] += (inputData[ySpace][xSpace] * cos(
                            2 * PI * ((1.0 * xWave * xSpace / width) + (1.0
                                    * yWave * ySpace / height)))) / sqrt(
                            width * height);
                    imagOut[yWave][xWave] -= (inputData[ySpace][xSpace] * sin(
                            2 * PI * ((1.0 * xWave * xSpace / width) + (1.0
                                    * yWave * ySpace / height)))) / sqrt(
                            width * height);
                    amplitudeOut[yWave][xWave] = sqrt(
                            realOut[yWave][xWave] * realOut[yWave][xWave]
                                    + imagOut[yWave][xWave]
                                            * imagOut[yWave][xWave]);
                }
                printf(" %e + %e i (%e)\n", realOut[yWave][xWave],
                        imagOut[yWave][xWave], amplitudeOut[yWave][xWave]);
            }
        }
    }
    return 0;
}