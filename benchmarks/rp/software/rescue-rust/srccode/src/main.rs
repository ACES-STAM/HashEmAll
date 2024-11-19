pub mod field;
mod rescue_prime;

use crate::field::{Field, FieldElement};
use num_bigint::BigUint;
use rescue_prime::RescuePrime;

fn main() {
    
    let shift = 1_u128 << 119;
    let p_value = 407_u128 * shift + 1;
    let modulus = BigUint::from(p_value);
    let field = Field::new(modulus.clone());
    let element1 = FieldElement::new(BigUint::from(4u32), field.clone());

    let rescueprime = RescuePrime::new();
    let hash_value = rescueprime.hash(element1);
    println!("\nHash Value: {}\n", hash_value.to_string());
}