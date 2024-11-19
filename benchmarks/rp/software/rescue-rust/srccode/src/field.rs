use num_bigint::BigUint;
use num_traits::One;
use num_traits::Zero;

#[derive(Clone, Debug)]
pub struct Field {
    modulus: BigUint,
}

impl Field {
    pub fn new(modulus: BigUint) -> Field {
        Field { modulus }
    }

    pub fn zero(&self) -> FieldElement {
        FieldElement::new(BigUint::zero(), self.clone())
    }

    pub fn add(&self, left: &FieldElement, right: &FieldElement) -> FieldElement {
        FieldElement::new((left.value.clone() + right.value.clone()) % &self.modulus, self.clone())
    }

    pub fn multiply(&self, left: &FieldElement, right: &FieldElement) -> FieldElement {
        FieldElement::new((left.value.clone() * right.value.clone()) % &self.modulus, self.clone())
    }

    pub fn subtract(&self, left: &FieldElement, right: &FieldElement) -> FieldElement {
        FieldElement::new((left.value.clone() + &self.modulus - right.value.clone()) % &self.modulus, self.clone())
    }

    pub fn divide(&self, left: &FieldElement, right: &FieldElement) -> FieldElement {
        self.multiply(left, &self.inverse(right))
    }

    fn negate(&self, element: &FieldElement) -> FieldElement {
        FieldElement::new(self.modulus.clone() - element.value.clone(), self.clone())
    }

    fn inverse(&self, element: &FieldElement) -> FieldElement {
        FieldElement::new(modular_inverse(&element.value, &self.modulus), self.clone())
    }
}

#[derive(Clone, Debug)]
pub struct FieldElement {
    value: BigUint,
    field: Field,
}

impl FieldElement {
    pub fn new(value: BigUint, field: Field) -> FieldElement {
        FieldElement { value, field }
    }

    // Addition
    pub fn add(&self, right: &FieldElement) -> FieldElement {
        self.field.add(self, right)
    }

    // Multiplication
    pub fn multiply(&self, right: &FieldElement) -> FieldElement {
        self.field.multiply(self, right)
    }

    // Subtraction
    pub fn subtract(&self, right: &FieldElement) -> FieldElement {
        self.field.subtract(self, right)
    }

    // Division
    pub fn divide(&self, right: &FieldElement) -> FieldElement {
        self.field.divide(self, right)
    }

    // Negation
    pub fn negate(&self) -> FieldElement {
        self.field.negate(self)
    }

    // Inverse
    pub fn inverse(&self) -> FieldElement {
        self.field.inverse(self)
    }

    // Equality
    pub fn eq(&self, other: &FieldElement) -> bool {
        self.value == other.value
    }

    pub fn xor(mut self, other: BigUint) -> FieldElement {
        let other_value = other;
        self.value ^= other_value;
        self

    }

    // Inequality
    pub fn neq(&self, other: &FieldElement) -> bool {
        self.value != other.value
    }

    // String representation
    pub fn to_string(&self) -> String {
        self.value.to_string()
    }

    // Byte representation
    pub fn to_bytes(&self) -> Vec<u8> {
        self.to_string().into_bytes()
    }

    // Check if value is zero
    pub fn is_zero(&self) -> bool {
        self.value.is_zero()
    }

    pub fn pow(&self, exponent: BigUint) -> Self {
        let one = BigUint::one();
        let zero = BigUint::zero();
        let mut acc = FieldElement::new(one.clone(), self.field.clone());
        let mut val = self.clone();
        let mut exp = exponent;

        while exp > zero {
            if &exp % 2_u32 == one {
                acc = acc.multiply(&val);
            }
            val = val.multiply(&val);
            exp /= 2_u32;
        }

        acc
    }
}

// Function to compute modular inverse using Extended Euclidean Algorithm
pub fn modular_inverse(a: &BigUint, modulus: &BigUint) -> BigUint {
    let (mut mn, mut xy) = (modulus.clone(), a.clone());
    let mut x = BigUint::zero();
    let mut y = BigUint::one();

    while xy != BigUint::zero() {
        let quotient = &mn / &xy;
        let temp_xy = xy.clone();
        xy = mn - (&quotient * &xy);
        mn = temp_xy;

        let temp_x = x.clone();
        x = y.clone();
        y = temp_x -( &quotient * &y);
    }

    while x < BigUint::zero() {
        x += modulus;
    }
    x
}
