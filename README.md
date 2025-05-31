# clearhide
A steganography tool that uses XOR in order to hide files. (Well, not exactly.)

## A massive warning  
Clearhide does not gurantee your data will be secure, as it depends on your disk device and your habits of using it!

## A few tips for users
Use a block device with high amounts of randomness (or entropy for the folks that get it)
Encrypt your payload with AES256 or something before you use clearhide to hide it.
Prefer to not use the same carrier for multiple files.

Do NOT lose all 3 parts! You can safely lose up to 2 elements that recover the data (the elements are the carrier, the generated file after hiding and seed)
You can lose 2 of it, and still be safe. But do NOT lose all 3! It will allow anyone to recover the hidden payload.

And, if any one of those elements are changed in the slightest way, clearhide can and WILL! recover garbage, silently. (It has no way to diffirentate the hidden payload from garbage data)

## Building
Requirements:
zig compiler 0.13.0 (This should compile on 0.14.X too) 

after cloning the repository, all you have to do is run `zig build-exe -OReleaseFast main.zig`


## Technicalities
clearhide is simply XORing a random part of carrier file (using a CSPRNG) with the payload data. the seed is outputted in stderr after the file has successfully been "hidden".
The payload is fragmented to random lenghts up to 512 bytes, and then the fragments are XORed with the carrier at a random offset. and then the XORed fragment is written to the
output file. The "random" algorithm is ChaCha CSPRNG in this case. So you will have to keep track of seeds aswell.

# Contributing
I am mostly looking for code reviews and critisism, but if you open a merge request with some good code, i likely won't say no to merging it. 
