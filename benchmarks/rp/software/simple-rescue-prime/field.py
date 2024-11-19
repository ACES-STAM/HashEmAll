class PrimeField:

    def __init__(self, modulus: int) -> None:
        self.modulus = modulus

    def add(self, elem1: int, elem2: int) -> int:
        return (elem1 + elem2) % self.modulus

    def sub(self, elem1: int, elem2: int):
        return (elem1 - elem2) % self.modulus

    def mul(self, elem1: int, elem2: int):
        return (elem1 * elem2) % self.modulus

    def exp(self, elem: int, power: int):
        return pow(elem, power, self.modulus)
