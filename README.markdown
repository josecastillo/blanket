Blanket — Trusted, Secure, Identity‑Free Mobile Messaging
=========================================================

**TL;DR**: Blanket lets you meet someone in person and exchange disposable public keys and credentials by generating and scanning QR codes. It then enables secure one-to-one text messaging using the libsodium library for public-key cryptography, and the iOS keychain for storing secrets. There is a test server set up at https://blanket.herokuapp.com/ so you should be able to run the iOS app and test it right out of the box. See ```SETUP.markdown``` for details.

What is Blanket? 
----------------

Blanket is intended as a proof of concept for secure, trusted, one-to-one messaging on mobile devices. Encrypted text messaging systems for exist already; indeed, iOS ships with iMessage, which is encrypted out of the box. Blanket's key feature is not encryption, but rather a simplified trust model that authenticates conversation participants on the client side, while maintaining full anonymity on the server side. It also encrypts all messages going through the service (duh). 

It needs some review before anyone should really trust it; this is my first attempt a cryptography app, so take it for what it is: an attempt to explore some ideas, but not yet a bulletproof cryptography system. Having said that, it attempts to leverage some well-known and trusted systems — the **libsodium** library for public-key cryptography, and the **iOS Keychain** API for storing secrets — and tries not to be too clever in their application. I would welcome someone with crypto experience looking at this code and telling me if and/or how much I screwed up. 

Blanket's Goals
---------------

 * **Security** — Messages in Blanket are encrypted on the client side, and stored on the server in a manner that only the recipient can decrypt. The blanket server merely accepts ciphertext from the client; it does no encryption or validation of its own, and never sees the clients' keys or any identifying information. 
 * **Loose identity** — Messages are cryptographically signed, but the keys used for encrypting and signing are generated per-conversation, not per-person. Thus, cryptographic keys are tied to a _relationship_, not an _identity_. Alice's secret key for talking to Bob is completely different from her secret key for talking to Charlie. Keys are exchanged in person by scanning QR codes; they are designed to be cheap and disposable, as opposed to GPG keys which are tied more strongly to your identity. 
 * **Simple trust** — Since there is no sense of "identity" on blanket, there is no centralized authority vouching for a person's identity, nor is there a complex "web of trust" for validating identities. By design, Alice's conversation with Bob deserves no more (and no less) trust than Alice puts in the person named Bob with whom she met and swapped keys. 

Explaining the use case for Blanket
-----------------------------------

While there are many applications for secure and trusted communications, the following use case illustrates some of the concepts that informed Blanket's design. 

A government employee (Alice) wishes to expose abuse within the agency she works for. However, the current administration's [dogged pursuit of whistleblowers](http://www.techdirt.com/articles/20130726/01200123954/obama-promise-to-protect-whistleblowers-just-disappeared-changegov.shtml) makes her fear that even speaking to a journalist would lead to retaliation and persecution. How can Alice protect herself if she fears her government is [monitoring her communications](http://www.theguardian.com/world/2013/jul/31/nsa-top-secret-program-online-data)? 

Alternatively: A journalist (Bob) is dealing with a source (Alice) exposing abuse in her agency. She can confirm her identity privately, but wishes to remain anonymous in press reports. Bob worries not only about surveillance of their conversation, but also that the government could [sieze records of his communications](http://www.nytimes.com/2013/05/14/us/phone-records-of-journalists-of-the-associated-press-seized-by-us.html?pagewanted=all) with Alice at any time. How can Bob promise to protect his source when he cannot be certain his communications are secure at all? 

With Blanket: Alice and Bob can arrange to meet offline, in a real world setting, and exchange keys in person. Note that Alice may not trust Bob completely — nor may he completely trust her — but once they leave their in-person meeting, they can at least trust that they are talking to the same person they met previously. 

Both Alice's and Bob's secret keys are stored locally on their devices, encrypted with the iOS Keychain API. The keychain on iOS is encrypted using a key derived, in part, from the passcode set by the user. Assuming they have reasonably strong passcodes set — Apple's documentation suggests that [even a nine digit passcode](http://images.apple.com/iphone/business/docs/iOS_Security_Oct12.pdf) is enough to delay a brute force attack — they can be reasonably certain that even the seizure of their devices would not lead to the exposure of their communications. 

The messages Alice and Bob transmit to the Blanket server are encrypted on the client-side; the database stores only ciphertext, random data and a timestamp alongside the conversation identifier. 

For more information about how Blanket works, check out ```MORE_INFO.markdown```
