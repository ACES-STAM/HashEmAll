#[allow(clippy::too_many_arguments)]
pub mod bls12;
pub mod bn254; // Add this line to include the bn254 module

#[allow(clippy::too_many_arguments)]
pub mod bn256;
pub mod const_f31;
pub mod const_f64;
pub mod f31;
pub mod f64;
#[allow(clippy::too_many_arguments)]
pub mod st;
pub mod utils;
pub mod utils4;
// sage:
// p = 21888242871839275222246405745257275088548364400416034343698204186575808495617
// F = GF(p)
// F.multiplicative_generator()
// F(7).is_primitive_root()
