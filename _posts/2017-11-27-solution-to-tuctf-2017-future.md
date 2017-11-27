---
layout: post
title: "Solution to TUCTF 2017 Future task"
author: capitol
category: ctf
---
![binary_search_tree](/images/binary_search_tree.png)

##### name:
Future

##### category:
reverse

##### points:
250

#### Writeup

We received a small c program that implemented a simple hash funktion. 

In the program was a string that represented a hashed password and a simple hash implementation, our task was to find out what input string hashed into the byte array named pass.

The hash algorithm consisted of two steps.

* A reordering of the original input string into a array in memory. Implemented in the function genMatrix.
* The creation of the hashed by adding different bytes from the original string together. Implemented in the function genAuthString.

This was the source code of the given problem:

```c 
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

void genMatrix(char mat[5][5], char str[]) {
        for (int i = 0; i < 25; i++) {
                int m = (i * 2) % 25;
                int f = (i * 7) % 25;
                mat[m/5][m%5] = str[f];
        }
}

void genAuthString(char mat[5][5], char auth[]) {
        auth[0] = mat[0][0] + mat[4][4];
        auth[1] = mat[2][1] + mat[0][2];
        auth[2] = mat[4][2] + mat[4][1];
        auth[3] = mat[1][3] + mat[3][1];
        auth[4] = mat[3][4] + mat[1][2];
        auth[5] = mat[1][0] + mat[2][3];
        auth[6] = mat[2][4] + mat[2][0];
        auth[7] = mat[3][3] + mat[3][2] + mat[0][3];
        auth[8] = mat[0][4] + mat[4][0] + mat[0][1];
        auth[9] = mat[3][3] + mat[2][0];
        auth[10] = mat[4][0] + mat[1][2];
        auth[11] = mat[0][4] + mat[4][1];
        auth[12] = mat[0][3] + mat[0][2];
        auth[13] = mat[3][0] + mat[2][0];
        auth[14] = mat[1][4] + mat[1][2];
        auth[15] = mat[4][3] + mat[2][3];
        auth[16] = mat[2][2] + mat[0][2];
        auth[17] = mat[1][1] + mat[4][1];
}

int main() {
        char flag[26];
        printf("What's the flag: ");
        scanf("%25s", flag);
        flag[25] = 0;

        if (strlen(flag) != 25) {
                puts("Try harder.");
                return 0;
        }


        // Setup matrix
        char mat[5][5];// Matrix for a jumbled string
        genMatrix(mat, flag);
        // Generate auth string
        char auth[19]; // The auth string they generate
        auth[18] = 0; // null byte
        genAuthString(mat, auth);       
        char pass[19] = "\x8b\xce\xb0\x89\x7b\xb0\xb0\xee\xbf\x92\x65\x9d\x9a\x99\x99\x94\xad\xe4\x00";
        
        // Check the input
        if (!strcmp(pass, auth)) {
                puts("Yup thats the flag!");
        } else {
                puts("Nope. Try again.");
        }
        
        return 0;
}
``` 

Looking at the genAuthString method, we noticed that all but two of the equations only added two bytes, and we guessed that the flag only contained ascii characters. Since two ascii characters added are never more than 256 we didn't have to worry about overflows for those, and if we got an overflow on the bytes with 3 values then we could handle that manually.

This meant that the hashing algorithm could be represented as a system of linear equations, and we knew that the flag was on the format TUCTF{...} so we had a seven characters of plain text.

We wrote a small program that printed the equations:

```c
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

void genMatrix(char mat[5][5], char str[]) {
  for (int i = 0; i < 25; i++) {
    int m = (i * 2) % 25;
    int f = (i * 7) % 25;
    mat[m/5][m%5] = str[f];
  }
}

void printEquations(char mat[5][5], unsigned char auth[]) {
  printf("%c + %c = %u\n", mat[0][0], mat[4][4], auth[0]);
  printf("%c + %c = %u\n", mat[2][1], mat[0][2], auth[1]);
  printf("%c + %c = %u\n", mat[4][2], mat[4][1], auth[2]);
  printf("%c + %c = %u\n", mat[1][3], mat[3][1], auth[3]);
  printf("%c + %c = %u\n", mat[3][4], mat[1][2], auth[4]);
  printf("%c + %c = %u\n", mat[1][0], mat[2][3], auth[5]);
  printf("%c + %c = %u\n", mat[2][4], mat[2][0], auth[6]);
  printf("%c + %c + %c = %u\n", mat[3][3], mat[3][2], mat[0][3], auth[7]);
  printf("%c + %c + %c = %u\n", mat[0][4], mat[4][0], mat[0][1], auth[8]);
  printf("%c + %c = %u\n", mat[3][3], mat[2][0], auth[9]);
  printf("%c + %c = %u\n", mat[4][0], mat[1][2], auth[10]);
  printf("%c + %c = %u\n", mat[0][4], mat[4][1], auth[11]);
  printf("%c + %c = %u\n", mat[0][3], mat[0][2], auth[12]);
  printf("%c + %c = %u\n", mat[3][0], mat[2][0], auth[13]);
  printf("%c + %c = %u\n", mat[1][4], mat[1][2], auth[14]);
  printf("%c + %c = %u\n", mat[4][3], mat[2][3], auth[15]);
  printf("%c + %c = %u\n", mat[2][2], mat[0][2], auth[16]);
  printf("%c + %c = %u\n", mat[1][1], mat[4][1], auth[17]);
  printf("a = 84\n");
  printf("b = 85\n");
  printf("c = 67\n");
  printf("d = 84\n");
  printf("e = 70\n");
  printf("f = 123\n");
  printf("y = 124\n");
}

int main() {
  char* flag = "abcdefghijklmnopqrstuvwxy";
  char mat[5][5];// Matrix for a jumbled string
  unsigned char pass[19] = "\x8b\xce\xb0\x89\x7b\xb0\xb0\xee\xbf\x92\x65\x9d\x9a\x99\x99\x94\xad\xe4\x00";  
  genMatrix(mat, flag);
  printEquations(mat, pass);
}
```

After we had the equation system we just used this solver: https://quickmath.com/webMathematica3/quickmath/equations/solve/advanced.jsp

And got these results:
a=84
b=85
c=67
d=84
e=70
f=123
g=53
h=121
i=53
j=55
k=t1
l=109
m=53
n=94
o=48
p=101
q=95
r=52
s=95
t=100
u=48
v=119
w=111
x=33
y=124

which translates to
TUCTF{5y573m5_0f_4_d0wn!}
