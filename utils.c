#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/stat.h>

// returns a heap allocated block that contains data of `data` XOR'ed with `src` with length of n bytes.
// NULL on error, data and src must be same length.
char* xorify(char* data, char* src, size_t n)
{
    char* result = malloc(n);
    if (result == NULL) return NULL;
    for (int i = 0; i < n; i++)
    {
        result[i] = data[i] ^ src[i];
    }
    return result;
}

// simply gets the file length in bytes.
size_t getFileLen(int fileFd)
{
    struct stat fileStat;
    if (fstat(fileFd, &fileStat) == -1) return 0;
    return fileStat.st_size;
}

// lseek's backwards n bytes on fd
void seekBack(int fd, size_t n)
{
    lseek(fd, (lseek(fd, 0, SEEK_CUR) - n), SEEK_SET);
}