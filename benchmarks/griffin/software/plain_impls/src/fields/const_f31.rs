use super::f31::{F31Repr, Field32};
use ff::{Field, PrimeField, SqrtField};
use rand::Rand;
use serde::{Deserialize, Serialize};
use std::{
    fmt::Display,
    ops::{Add, AddAssign, BitXorAssign, Mul, MulAssign, Sub, SubAssign},
};

#[derive(
    Debug, Copy, Clone, PartialEq, Eq, Default, Hash, PartialOrd, Ord, Serialize, Deserialize,
)]
#[repr(transparent)]
pub struct ConstF31 {
    pub v: u32,
}

impl ConstF31 {
    pub const FIELD_SIZE: u32 = 0x7FFFFFFF;
    pub const NUM_BYTES: usize = 4; //number of bytes in the modulus
    pub const D_VALUE: u64 = 5; // min prime such that x^d is a permutation
}

impl Rand for ConstF31 {
    fn rand<R: rand::Rng>(rng: &mut R) -> Self {
        loop {
            let v = rng.gen();
            if v < Self::FIELD_SIZE {
                return Self { v };
            }
        }
    }
}

impl Display for ConstF31 {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.v)
    }
}

impl From<u64> for ConstF31 {
    fn from(v: u64) -> Self {
        Self { v: v as u32 }
    }
}

impl Add for ConstF31 {
    type Output = Self;

    fn add(self, other: ConstF31) -> Self {
        let mut tmp = self.v + other.v;
        let msb = tmp & (1 << 31);
        tmp.bitxor_assign(msb);
        tmp += (msb != 0) as u32;
        Self { v: tmp }
    }
}

impl AddAssign<&ConstF31> for ConstF31 {
    fn add_assign(&mut self, other: &ConstF31) {
        self.v += other.v;
        let msb = self.v & (1 << 31);
        self.v.bitxor_assign(msb);
        self.v += (msb != 0) as u32;
    }
}

impl Sub for ConstF31 {
    type Output = Self;

    fn sub(self, other: ConstF31) -> Self {
        let neg = Self::FIELD_SIZE - other.v;
        let mut tmp = self.v + neg;
        let msb = tmp & (1 << 31);
        tmp.bitxor_assign(msb);
        tmp += (msb != 0) as u32;
        Self { v: tmp }
    }
}

impl SubAssign<&ConstF31> for ConstF31 {
    fn sub_assign(&mut self, other: &ConstF31) {
        let neg = Self::FIELD_SIZE - other.v;
        self.v += neg;
        let msb = self.v & (1 << 31);
        self.v.bitxor_assign(msb);
        self.v += (msb != 0) as u32;
    }
}

impl Mul for ConstF31 {
    type Output = Self;

    fn mul(self, other: ConstF31) -> Self {
        let x = (self.v as u64) * (other.v as u64);
        Self::reduce(&x)
    }
}

impl MulAssign<&ConstF31> for ConstF31 {
    fn mul_assign(&mut self, other: &ConstF31) {
        let x = (self.v as u64) * (other.v as u64);
        let x_lo = (x as u32) & Self::FIELD_SIZE;
        let x_hi = (x >> 31) as u32;
        self.v = x_lo + x_hi;
        let msb = self.v & (1 << 31);
        self.v.bitxor_assign(msb);
        self.v += (msb != 0) as u32;
    }
}

impl Field for ConstF31 {
    fn zero() -> Self {
        Self { v: 0 }
    }

    fn one() -> Self {
        Self { v: 1 }
    }

    fn is_zero(&self) -> bool {
        self.v == 0
    }

    fn square(&mut self) {
        *self = *self * *self
    }

    fn double(&mut self) {
        *self = *self + *self
    }

    fn negate(&mut self) {
        *self = Self::zero() - *self
    }

    fn add_assign(&mut self, other: &Self) {
        *self += other;
    }

    fn sub_assign(&mut self, other: &Self) {
        *self -= other;
    }

    fn mul_assign(&mut self, other: &Self) {
        *self *= other;
    }

    // This is *not* constant-time!
    fn inverse(&self) -> Option<Self> {
        if self.v == 0 {
            return None;
        }

        let mut mod_ = Self::FIELD_SIZE;
        let mut prev_a = 1i32;
        let mut a = 0i32;
        let mut val = self.v;

        while mod_ != 0 {
            let q = (val / mod_) as i32;
            let mut tmp = (val % mod_) as i32;
            val = mod_;
            mod_ = tmp as u32;

            tmp = a;
            a = prev_a - q.overflowing_mul(a).0;
            prev_a = tmp;
        }
        let mut res = prev_a as u32;
        if prev_a < 0 {
            res = res.wrapping_add(Self::FIELD_SIZE);
        }
        let res = Self { v: res };

        debug_assert!(res * *self == Self::one());
        Some(res)
    }

    fn frobenius_map(&mut self, _power: usize) {
        // This has no effect in a prime field.
    }

    fn pow<S: AsRef<[u64]>>(&self, _exp: S) -> Self {
        panic!("Not implemented")
    }
}

impl From<ConstF31> for u32 {
    fn from(v: ConstF31) -> Self {
        v.v
    }
}

impl From<ConstF31> for F31Repr {
    fn from(v: ConstF31) -> Self {
        Self { v: v.v as u64 }
    }
}

impl PrimeField for ConstF31 {
    type Repr = F31Repr;

    fn from_repr(repr: Self::Repr) -> Result<Self, ff::PrimeFieldDecodingError> {
        if repr.v > Self::FIELD_SIZE as u64 {
            return Err(ff::PrimeFieldDecodingError::NotInField(
                "Not in Field".to_string(),
            ));
        }
        Ok(Self { v: repr.v as u32 })
    }

    fn from_raw_repr(repr: Self::Repr) -> Result<Self, ff::PrimeFieldDecodingError> {
        Self::from_repr(repr)
    }

    fn into_repr(&self) -> Self::Repr {
        Self::Repr { v: self.v as u64 }
    }

    fn into_raw_repr(&self) -> Self::Repr {
        self.into_repr()
    }

    fn char() -> Self::Repr {
        Self::Repr {
            v: Self::FIELD_SIZE as u64,
        }
    }

    const NUM_BITS: u32 = 31;

    const CAPACITY: u32 = Self::NUM_BITS - 1;

    fn multiplicative_generator() -> Self {
        Self { v: 7 }
    }

    const S: u32 = 1;

    fn root_of_unity() -> Self {
        Self { v: 2147483643 }
    }
}

// This is *not* constant-time!
impl SqrtField for ConstF31 {
    fn legendre(&self) -> ff::LegendreSymbol {
        let s = self.pow([1073741823u64]);
        if s == Self::zero() {
            crate::ff::LegendreSymbol::Zero
        } else if s == Self::one() {
            crate::ff::LegendreSymbol::QuadraticResidue
        } else {
            crate::ff::LegendreSymbol::QuadraticNonResidue
        }
    }

    fn sqrt(&self) -> Option<Self> {
        let mut a1 = self.pow([536870911u64]);
        let mut a0 = a1;
        a0.square();
        a0 *= self;
        if a0.v == 2147483643 {
            None
        } else {
            a1 *= self;
            Some(a1)
        }
    }
}

impl Field32 for ConstF31 {
    fn reduce(el: &u64) -> Self {
        let el_lo: u32 = (*el as u32) & Self::FIELD_SIZE;
        let el_hi = (*el >> 31) as u32;
        Self { v: el_lo } + Self { v: el_hi }
    }

    fn to_u32(&self) -> u32 {
        self.v
    }

    fn from_u32(x: u32) -> Self {
        debug_assert!(x < Self::FIELD_SIZE);
        Self { v: x }
    }

    fn from_u64(x: u64) -> Self {
        Self::reduce(&x)
    }

    fn reduce64(x: &mut u64) {
        let x_lo = *x & Self::FIELD_SIZE as u64;
        let x_hi = *x >> 31;
        *x = x_lo + x_hi;
        let msb = *x & (1 << 31);
        x.bitxor_assign(msb);
        *x += (msb != 0) as u64;
    }
}

#[cfg(test)]
mod f31_field_test {
    use super::*;

    use rand::{thread_rng, Rng};
    static TESTRUNS: usize = 5;

    #[allow(non_snake_case)]
    #[test]
    fn kats() {
        let v1 = 0xFFFFFFF;
        let v2 = 0x7FFFFFFE;
        let X1 = ConstF31 { v: v1 };
        let X2 = ConstF31 { v: v2 };

        //add and sub test
        let X3 = X1 + X2;
        let X3_check = ConstF31 {
            v: ((v1 as u64 + v2 as u64) % (ConstF31::FIELD_SIZE as u64)) as u32,
        };
        let X4 = X1 - X2;
        let X4_check = ConstF31 {
            v: ((ConstF31::FIELD_SIZE as u64 + v1 as u64 - v2 as u64)
                % (ConstF31::FIELD_SIZE as u64)) as u32,
        };
        assert_eq!(X3, X3_check);
        assert_eq!(X4, X4_check);

        //mul test
        let X5 = X1 * X2;
        let X5_check = ConstF31 {
            v: (((v1 as u64) * (v2 as u64)) % (ConstF31::FIELD_SIZE as u64)) as u32,
        };
        assert_eq!(X5, X5_check);

        let i = X5.inverse().unwrap();
        assert_eq!(i * X5, ConstF31::one());
    }

    #[test]
    fn test() {
        let mut rng = thread_rng();
        for _ in 0..TESTRUNS {
            let inp1 = ConstF31 {
                v: rng.gen_range::<u32>(0, ConstF31::FIELD_SIZE),
            };
            let inp2 = ConstF31 {
                v: rng.gen_range::<u32>(0, ConstF31::FIELD_SIZE),
            };

            let add = inp1 + inp2;
            let sub = inp1 - inp2;
            let mul = inp1 * inp2;

            let mut add_ass = inp1;
            add_ass += &inp2;
            let mut sub_ass = inp1;
            sub_ass -= &inp2;
            let mut mul_ass = inp1;
            mul_ass *= &inp2;

            assert_eq!(add, add_ass);
            assert_eq!(sub, sub_ass);
            assert_eq!(mul, mul_ass);

            assert!(add.v < ConstF31::FIELD_SIZE);
            assert!(sub.v < ConstF31::FIELD_SIZE);
            assert!(mul.v < ConstF31::FIELD_SIZE);
        }
    }
}
