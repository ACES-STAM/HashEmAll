
pub mod field;
pub mod reinforced_concrete;

use crate::field::{Field, FieldElement};
use num_bigint::BigUint;
use std::str::FromStr;
use hex;

use reinforced_concrete::ReinforcedConcrete;

fn main() {
    
    
    let p_value_str = "21888242871839275222246405745257275088548364400416034343698204186575808495617";
    
    let modulus = BigUint::from_str(p_value_str).expect("Failed to parse the number");
    let field = Field::new(modulus.clone());
    let field_value1: u32 = 7;
    let field_value2: u32 = 5;
    let field_gen1 = BigUint::from(field_value1);
    let field_gen2 = BigUint::from(field_value2);
    let element1 = FieldElement::new(field_gen1, field.clone());
    let element2 = FieldElement::new(field_gen2, field.clone());


    let reinforcedconcrete = ReinforcedConcrete::new();
    let hash_value = reinforcedconcrete.hash_function(&element1, &element2);
    // let hex_string = hex::encode(hash_value.to_bytes());
    // println!("\nHash encoded Value : {}\n", hex_string);
    println!("\nHash Value: {}\n", hash_value.to_string());
    println!("we dey here again")
}
