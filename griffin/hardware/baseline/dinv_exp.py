def square_and_multiply(base, exponent, modulus):
    result = 1
    current_power = base % modulus  # Start with base modulo modulus

    while exponent > 0:
        if (exponent % 2) == 1:  # If the current bit is 1
            result = (result * current_power) % modulus  # Multiply
        current_power = (current_power * current_power) % modulus  # Square
        exponent //= 2  # Shift right (divide by 2)

    return result


import random
#base = random.getrandbits(254)  # 253 bits random
    # Set the highest bit to 1 to ensure it's 254 bits
base = 1056050606199152751036190847049222475507318246021320286926956279504387209712
dinv = 0x26b6a528b427b35493736af8679aad17535cb9d394945a0dcfe7f7a98ccccccd
modulus = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001
result = square_and_multiply(base, dinv, modulus)
print(f"input is {base}")
correct = pow(base, dinv, modulus)
print(hex(correct))
for i in range(5):
    print(hex(pow(base, i+1, modulus)))