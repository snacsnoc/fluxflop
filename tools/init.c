#include <unistd.h>
#include <stdio.h>

int main(void) {
    printf("hello, world!\n");
    fflush(stdout); 

    // start an interactive shell
    char *argv[] = {"/bin/sh", "-i", NULL};
    execv("/bin/sh", argv);

    // if execv fails
    perror("Failed to start /bin/sh");
    while (1) {
        sleep(1); 
    }

    return 0;
}
