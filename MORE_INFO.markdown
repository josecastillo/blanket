More about Blanket
==================

Key Exchange / Starting a Conversation
--------------------------------------

In key exchange, both parties must generate a QR code and both parties must scan a QR code. Alice could generate first or scan first, but for the sake of the demonstration, we'll have her generate a code first. 

Using the Sodium crypto library, Alice generates a keypair for her conversation with Bob (a 32-byte _public key_ and a 32-byte _secret key_). In addition, Alice generates a 16 byte _conversation identifier_ (like a username), and a 16-byte _access code_ (like a password) for posting messages to the server. Alice will need to send Bob the public key, the identifier and the access code, along with her name (Alice) for display purposes. 

We bundle all this information in a string of bytes with the following format: 

* Version string, "SB01" (4 bytes)
* Conversation identifier I (16 bytes)
* Access code C (16 bytes)
* Public key AK (32 bytes)
* Alice's name (UTF8-encoded, variable length)

The string will look like this: 

    SB01IIIIIIIIIIIIIIIICCCCCCCCCCCCCCCCAKAKAKAKAKAKAKAKAKAKAKAKAKAKAKAKAlice

Since this string contains non-ASCII characters, we base-64 encode it. From there, we generate a QR code with that base 64 string, and present it on screen for Bob to scan. 

Bob's device will obtain the conversation identifier and access code from the scanned data; he will then use the Sodium library to generate his own keypair. Bob generates a string identical in structure to Alice's, with two differences (in bold): 

* Version string, "SB01" (4 bytes)
* Conversation identifier I (16 bytes)
* Access code C (16 bytes)
* **Public key BK** (32 bytes)
* **Bob's name** (Unicode, variable length)

His string will look like this: 

    SB01IIIIIIIIIIIIIIIICCCCCCCCCCCCCCCCBKBKBKBKBKBKBKBKBKBKBKBKBKBKBKBKBob
    
Same process: Bob base-64 encodes his string and presents it as a QR code. Alice needs to scan this code to complete the conversation generation process; when she does, she checks to make sure the conversation identifier and access code match, and then stores Bob's public key and name. 

She then posts an "open conversation" command to the Blanket server, establishing a secure channel for her and Bob to speak in. 

Finally, Bob finishes the process by confirming with the server that the conversation exists and is open. With that, the secure channel is established; and Alice and Bob may begin exchanging messages securely. 

Message Transmission
--------------------

Alice wishes to send a message, "Good morning!" to Bob. All messages in Blanket are UTF-8 encoded, and limited to 256 bytes of in length. Additionally, if a message is shorter than 256 bytes, it is padded with a null terminator, followed by enough random bytes to make the message 256 bytes long. In this way, every message on Blanket is of uniform length; if the database is compromised, the length of messages will thus be obscured. 

Alice takes her message, "Good Morning!", adds a null terminator, and pads it to 256 bytes (the tilde represents padding bytes): 

     G o o d   m o r n i n g !\0 ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ...
    476F6F64206D6F726E696E672100912C50501A7BD680BC9C63EA366FDCCD1E0C0C589E0FF4783D47 ... 

Alice generates a _nonce_ for the Sodium crypto library to use; she then encrypts this message **twice**. First she encrypts the message using her own public key and secret key, and stores it as _localData_. She then encrypts the message using Bob's public key and her secret key, storing this as _outgoingData_. Alice now has two strings of ciphertext that are 288 bytes long (Sodium prepends 32 zero bytes at the beginning): 

    localData: 
    000000000000000000000000000000004F2CB45640373B4EB10A94790F95FA9DE51A4BA8A2D3390C ...
    outgoingData: 
    000000000000000000000000000000006E2ABB5D65008185B1213C1E5A03F4031CEBB06AE3CA9FF0 ...

Alice authenticates with the Blanket server using the conversation identifier and access code she swapped with Bob. She base64 encodes the ciphertext and the nonce, and transmits them to the Blanket server. 

The server responds with a timestamp, representing the time the message was received. Alice now stores localData in her local record of the conversation, along with the timestamp, nonce and a flag indicating an outgoing message. Alice can decrypt this locally stored message using her public and secret key. 

When Bob wishes to receive this message, he authenticates with the server using the conversation identifier and access code he swapped with Alice. He also provides the timestamp of the last time he synced with the server. The blanket server responds with the ciphertext Alice sent, as well as the timestamp and nonce. Bob stores this ciphertext in his local record of the conversation, along with a flag indicating an incoming message. Bob can decrypt and authenticate this message using his secret key and Alice's public key. 

What about security breaches and data seizures?
-----------------------------------------------

If Blanket has done its job, an attacker should be able to sieze the entire database, and only minimal information would be leaked. Conversation identifiers and the timestamps of associated messages are stored in plaintext, but identifiers are random UUIDs not tied to an identity, messages are encrypted, and access codes are salted and hashed. If an attacker were to brute-force the access code for a channel he could post data to the channel; but without obtaining the 256-bit secret key of one participant and the 256-bit public key of the other, he would not be able to post a fraudulent message or decrypt any messages. 

External Dependencies
---------------------

The Blanket client should be portable to any platform, although you really need two things (and sort of need a third one) to make it work: 

 * *Secure storage for secret keys and access codes.* On iOS, the Keychain API is a perfect fit; the Keychain database is encrypted whenever the device is locked, and the decryption key is derived from the user's lock password. While four-digit PINs are weak and unsuitable for all but the most casual Blanket user, longer alphanumeric passwords promise to secure the Blanket user's secret keys quite well. Honestly, the only thing keeping me from porting this to Android today, is the lack of a similar OS-level secure storage API. 

 * *The Sodium encryption library.* A portable version of Daniel J. Bernstein's well-regarded NaCl library, [the Sodium encryption library](http://labs.umbrella.com/2013/03/06/announcing-sodium-a-new-cryptographic-library/) implements authenticated public-key encryption, and is used for all cryptography tasks in Blanket. All encryption happens on the client side; the server's job is simply to accept bytes of ciphertext and send them back out verbatim. 

 * *QR Code Generation and Scanning.* On iOS, we wrap up keypairs in Base 64 using [Matt Gallagher's NSData+Base64 category](http://www.cocoawithlove.com/2009/06/base64-encoding-options-on-mac-and.html). From there, we use [ObjQREncoder](https://github.com/jverkoey/ObjQREncoder) to encode the QR code, and the [ZBar SDK](http://zbar.sourceforge.net) to read those QR codes. Right now Blanket requires that people scan codes in order to encourage in-person key exchange; then again, the keys and credentials are just bytes; you can move them around however you want to. 
