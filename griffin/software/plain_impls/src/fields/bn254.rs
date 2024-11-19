use ff::{Field, PrimeField, PrimeFieldRepr}; // Import necessary traits from ff crate

cfg_if::cfg_if! {
    if #[cfg(feature = "asm")] {
        use ff::PrimeFieldAsm;

        #[derive(PrimeFieldAsm)]
        #[PrimeFieldModulus = "21888242871839275222246405745257275088548364400416034343698204186575808495617"] // BN254 modulus
        #[PrimeFieldGenerator = "3"]  // BN254 generator
        #[UseADX = "true"]
        pub struct FpBN254(FrRepr);  // Define BN254 prime field as FpBN254 with ASM support

    } else {
        #[derive(PrimeField)]
        #[PrimeFieldModulus = "21888242871839275222246405745257275088548364400416034343698204186575808495617"] // BN254 modulus
        #[PrimeFieldGenerator = "3"]  // BN254 generator
        pub struct FpBN254(FrRepr);  // Define BN254 prime field as FpBN254 without ASM
    }
}
