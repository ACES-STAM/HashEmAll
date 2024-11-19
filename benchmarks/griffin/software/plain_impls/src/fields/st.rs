use ff::{Field, PrimeField, PrimeFieldRepr};

cfg_if::cfg_if! {
    if #[cfg(feature = "asm")] {
        use ff::PrimeFieldAsm;

        #[derive(PrimeFieldAsm)]
        #[PrimeFieldModulus = "1798650311944395247515796855756291049112378607019380099367795112915886931969"]
        #[PrimeFieldGenerator = "3"]
        #[UseADX = "true"]
        pub struct FpST(FrRepr);

    } else {
        #[derive(PrimeField)]
        #[PrimeFieldModulus = "1798650311944395247515796855756291049112378607019380099367795112915886931969"]
        #[PrimeFieldGenerator = "3"]
        pub struct FpST(FrRepr);
    }
}
