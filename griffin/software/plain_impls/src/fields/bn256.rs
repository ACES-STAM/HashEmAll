use ff::{Field, PrimeField, PrimeFieldRepr};

cfg_if::cfg_if! {
    if #[cfg(feature = "asm")] {
        use ff::PrimeFieldAsm;

        #[derive(PrimeFieldAsm)]
        #[PrimeFieldModulus = "21888242871839275222246405745257275088548364400416034343698204186575808495617"]
        #[PrimeFieldGenerator = "7"]
        #[UseADX = "true"]
        pub struct FpBN256(FrRepr);

    } else {
        #[derive(PrimeField)]
        #[PrimeFieldModulus = "21888242871839275222246405745257275088548364400416034343698204186575808495617"]
        #[PrimeFieldGenerator = "7"]
        pub struct FpBN256(FrRepr);
    }
}
