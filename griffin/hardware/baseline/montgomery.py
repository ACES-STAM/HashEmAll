# # Montgomery multiplication and ladder
import random
def montgomery_reduce(t, p, n_inv, R):
    """Montgomery reduction: returns t * R^(-1) mod p."""
    m = (t * n_inv) % R
    t_prime = (t + m * p) // R
    if t_prime >= p:
        return t_prime - p
    else:
        return t_prime

def montgomery_multiply(a, b, p, n_inv, R):
    """Montgomery multiplication: a * b * R^(-1) mod p."""
    t = a * b
    return montgomery_reduce(t, p, n_inv, R)

def to_montgomery(x, p, R):
    """Convert x to Montgomery form: x * R mod p."""
    return (x * R) % p

def from_montgomery(x_mont, p, R_inv):
    """Convert x from Montgomery form: x * R^(-1) mod p."""
    return (x_mont * R_inv) % p

def montgomery_ladder_mont(x, e, p):
    """Montgomery Ladder using Montgomery multiplication."""
    # Step 1: Compute parameters for Montgomery arithmetic
    R = 1 << (p.bit_length())  # R = 2^k where k is the bit length of p
    R_inv = pow(R, -1, p)      # R^(-1) mod p
    n_inv = -pow(p, -1, R) % R # n^(-1) mod R

    # Step 2: Convert the base x to Montgomery form
    x_mont = to_montgomery(x, p, R)

    # Step 3: Initialize R0 = 1 (in Montgomery form) and R1 = x
    R0_mont = to_montgomery(1, p, R)  # Convert 1 to Montgomery form
    R1_mont = x_mont                  # Already in Montgomery form

    # Step 4: Perform the Montgomery Ladder exponentiation
    for i in range(e.bit_length() - 1, -1, -1):
        if (e >> i) & 1:  # If the i-th bit of e is 1
            R0_mont = montgomery_multiply(R0_mont, R1_mont, p, n_inv, R)
            R1_mont = montgomery_multiply(R1_mont, R1_mont, p, n_inv, R)
        else:             # If the i-th bit of e is 0
            R1_mont = montgomery_multiply(R0_mont, R1_mont, p, n_inv, R)
            R0_mont = montgomery_multiply(R0_mont, R0_mont, p, n_inv, R)

    # Step 5: Convert the result back from Montgomery form
    result = from_montgomery(R0_mont, p, R_inv)

    return result
def modular_exponentiation(x, dinv, p):
    return pow(x, dinv, p)

# Given values
dinv = 0x26b6a528b427b35493736af8679aad17535cb9d394945a0dcfe7f7a98ccccccd
p = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001


# Generate a random 254-bit number
# x = random.getrandbits(254)

# # Print the number
# print("x is", x)
# # Perform modular exponentiation
# correct = modular_exponentiation(x, dinv, p)
# result = montgomery_ladder_mont(x, dinv, p)
# print(correct == result)
# print("correct result is:", correct)

a = 0x2e7246c320355b8b9053b6e60b0eba343af3066737c38b2324cdb3932533a2c8
b = 0x0d62e11b4392bb8b7f1f2c9f5a8f94dee8d1e690944359498788e1849a5ca3bc
print(hex(pow(a,dinv,p)))
print(hex(pow(b,5,p)))