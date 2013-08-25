import string
import random

salt_characters = string.digits + string.letters + string.punctuation
sysrandom = random.SystemRandom()

def gen_salt(size):
    return ''.join(sysrandom.choice(salt_characters) for x in range(size))

def is_equal(a, b):
    if len(a) != len(b):
        return False

    result = 0
    for x, y in zip(a, b):
        result |= ord(x) ^ ord(y)
    return result == 0
