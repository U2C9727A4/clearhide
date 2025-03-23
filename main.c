#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include "utils.h"
#include <fcntl.h>


#define USAGE "ch device file device_offset output_file"

// ch device file device_offset output_file

int main(int argc, char** argv)
{
    char* device = argv[1];
    char* file = argv[2];
    long offset = atol(argv[3]);
    char* outputFile = argv[4];

    // Open the dang files

    int deviceFd = open(device, O_RDONLY);
    if (deviceFd < 0)
    {
        perror("Open(device) ");
        return EXIT_FAILURE;
    }
    int fileFd = open(file, O_RDONLY);
    if (fileFd < 0)
    {
        perror("Open(file) ");
        close(deviceFd);
        return EXIT_FAILURE;
    }
    int outputFileFd = open(outputFile, O_RDWR | O_CREAT, 0644);
    if (outputFileFd < 0)
    {
        perror("Open(device) ");
        close(deviceFd);
        close(fileFd);
        return EXIT_FAILURE;
    }

    size_t deviceLen = getFileLen(deviceFd);
    size_t fileLen = getFileLen(fileFd);

    if (offset < 0 || (deviceLen - offset) < fileLen)
    {
        printf("PANIC! Invalid offset.\n");
        close(deviceFd);
        close(fileFd);
        close(outputFileFd);
        return EXIT_FAILURE;
    }
    
    /*
        Error checks done, now we can finally read, and write.
    */
    lseek(deviceFd, offset, SEEK_SET);
    char buffer[BUFSIZ];
    char buffer2[BUFSIZ];
    size_t dataProcessed = 0;
    int retryAmount = 0;
    while (1)
    {
        retryAmount = 0;
        size_t dataLeft = fileLen - dataProcessed;
        // Get data we need to read during this iteration.
        size_t dataToRead = dataLeft > BUFSIZ ? BUFSIZ : dataLeft;
       // printf("data to read: %li\n", dataToRead);
       // printf("dataProcessed: %li\n", dataProcessed);
       // printf("File size: %li\n", fileLen);
        
        // Here, we read the device. We retry 5 times if we don't get the data we want.
        // if it exceeds 5 times, we exit the program.
        while (retryAmount < 5)
        {
            size_t bytesRead = read(deviceFd, buffer, dataToRead);
            if (bytesRead != dataToRead)
            {
                if (retryAmount == 5)
                {
                    close(deviceFd);
                    close(outputFileFd);
                    close(fileFd);
                    printf("PANIC! Unable to get required data after 5 retries!\n");
                    return EXIT_FAILURE;
                }
                seekBack(deviceFd, bytesRead);
                retryAmount++;
                continue;
            }
            if (bytesRead == dataToRead)
            {
                retryAmount = 0;
                break;
            }
            retryAmount++;
        }
        // Phew, thats a lotta code for retries!
        // Im just gonna copy-paste lol
        while (retryAmount < 5)
        {
            size_t bytesRead = read(fileFd, buffer2, dataToRead);
            if (bytesRead != dataToRead)
            {
                if (retryAmount == 5)
                {
                    close(deviceFd);
                    close(outputFileFd);
                    close(fileFd);
                    printf("PANIC! Unable to get required data after 5 retries!\n");
                    return EXIT_FAILURE;
                }
                seekBack(fileFd, bytesRead);
                retryAmount++;
                continue;
            }
            if (bytesRead == dataToRead)
            {
                retryAmount = 0;
                break;
            }
        }
        // We now have guranteed bytes to work with!
        char* xorredData = xorify(buffer, buffer2, dataToRead);
        if (xorredData == NULL)
        {
            perror("PANIC Malloc error! ");
            return EXIT_FAILURE;
        }
        dataProcessed += dataToRead; // Im gonna forget this later on prob
        
        while (retryAmount < 5)
        {
            size_t bytesRead = write(outputFileFd, xorredData, dataToRead);
            if (bytesRead != dataToRead)
            {
                if (retryAmount == 5)
                {
                    close(deviceFd);
                    close(outputFileFd);
                    close(fileFd);
                    printf("PANIC! Unable to write required data after 5 retries!\n");
                    return EXIT_FAILURE;
                }
                seekBack(fileFd, bytesRead);
                retryAmount++;
                continue;
            }
            if (bytesRead == dataToRead)
            {
                retryAmount = 0;
                break;
            }
        }
        free(xorredData);
        if (dataToRead < BUFSIZ) break;
    }
    close(deviceFd);
    close(fileFd);
    close(outputFileFd);
}
