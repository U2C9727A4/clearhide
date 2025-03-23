# clearhide
A steganography tool that uses XOR in order to hide files. (Well, not exactly.)

## A massive warning  
Clearhide does not gurantee your data will be secure, as it depends on your disk device and your habits of using it!

## A few tips for users
Use a block device with high amounts of randomness (or entropy for the folks that get it)  
Do not use the same part of the block device to hide more than 1 file.  

## Building
Requirements:
A C compiler (Dosen't matter if its gcc or clang)  
a POSIX C library (So you're gonna have to be on a UNIX or UNIX-Like system, or with mingw on windows)  
GNU make (or any other `make` command) OPTIONAL  

after cloning the repository, all you have to do is run `make build`
If you don't have `make`, all you have to do is run the command in the makefile yourself manually.


## Technicalities
clearhide is just XORing a part of a block device (disk devices are called block devices on linux, clearhide works on any UNIX system) with the file you want to hide.  
However, clearhide requires the part of the block device to be the same length as the file you're hiding, which depending on your block devices randomness, can generate/mimic a OTP.  
(Please look at wikipedia about OTPs https://en.wikipedia.org/wiki/One-time_pad)  
Its security depends mostly on your habits, and your block device's randomness.  
You use a part of the block device to hide more than 1 file, it compromises security.  
If you use a block device with low entropy, it also compromises security.  

# Contributing
I am mostly looking for code reviews and critisism, but if you open a merge request with some good code, i likely won't say no to merging it. 
