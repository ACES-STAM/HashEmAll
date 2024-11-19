use ff::{Field, PrimeField, PrimeFieldRepr, SqrtField};
use rand::Rand;
use serde::{Deserialize, Serialize};
use std::{
    fmt::Display,
    ops::{Add, AddAssign, Mul, MulAssign, Sub, SubAssign},
    slice,
};

#[derive(
    Debug, Copy, Clone, PartialEq, Eq, Default, Hash, PartialOrd, Ord, Serialize, Deserialize,
)]
#[repr(transparent)]
pub struct F31 {
    pub v: u32,
}

impl F31 {
    pub const FIELD_SIZE: u32 = 0x7FFFFFFF;
    pub const NUM_BYTES: usize = 4; //number of bytes in the modulus
    pub const D_VALUE: u64 = 5; // min prime such that x^d is a permutation
}

impl Rand for F31 {
    fn rand<R: rand::Rng>(rng: &mut R) -> Self {
        loop {
            let v = rng.gen();
            if v < Self::FIELD_SIZE {
                return Self { v };
            }
        }
    }
}

impl Display for F31 {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.v)
    }
}

impl From<u64> for F31 {
    fn from(v: u64) -> Self {
        Self { v: v as u32 }
    }
}

impl Add for F31 {
    type Output = Self;

    fn add(self, other: F31) -> Self {
        let tmp = self.v + other.v;
        if tmp > Self::FIELD_SIZE {
            Self {
                v: tmp - Self::FIELD_SIZE,
            }
        } else {
            Self { v: tmp }
        }
    }
}

impl AddAssign<&F31> for F31 {
    fn add_assign(&mut self, other: &F31) {
        let tmp = self.v + other.v;
        if tmp > Self::FIELD_SIZE {
            self.v = tmp - Self::FIELD_SIZE;
        } else {
            self.v = tmp;
        }
    }
}

impl Sub for F31 {
    type Output = Self;

    fn sub(self, other: F31) -> Self {
        if self.v >= other.v {
            Self {
                v: self.v - other.v,
            }
        } else {
            Self {
                v: (Self::FIELD_SIZE - other.v) + self.v,
            }
        }
    }
}

impl SubAssign<&F31> for F31 {
    fn sub_assign(&mut self, other: &F31) {
        if self.v >= other.v {
            self.v -= other.v;
        } else {
            self.v += Self::FIELD_SIZE - other.v;
        }
    }
}

impl Mul for F31 {
    type Output = Self;

    fn mul(self, other: F31) -> Self {
        let x = (self.v as u64) * (other.v as u64);
        Self::reduce(&x)
    }
}

impl MulAssign<&F31> for F31 {
    fn mul_assign(&mut self, other: &F31) {
        let x = (self.v as u64) * (other.v as u64);
        let x_lo = (x as u32) & Self::FIELD_SIZE;
        let x_hi = (x >> 31) as u32;
        let res = x_lo + x_hi;
        if res > Self::FIELD_SIZE {
            self.v = res - Self::FIELD_SIZE;
        } else {
            self.v = res;
        }
    }
}

impl Field for F31 {
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

    fn pow<S: AsRef<[u64]>>(&self, exp: S) -> Self {
        let mut res = Self::one();

        let mut found_one = false;

        for i in ff::BitIterator::new(exp) {
            if found_one {
                res.square();
            } else {
                found_one = i;
            }

            if i {
                res *= self;
            }
        }

        res
    }
}

impl From<F31> for u32 {
    fn from(v: F31) -> Self {
        v.v
    }
}

#[derive(
    Debug, Copy, Clone, PartialEq, Eq, Default, Hash, PartialOrd, Ord, Serialize, Deserialize,
)]
#[repr(transparent)]
pub struct F31Repr {
    pub v: u64,
}

impl From<F31> for F31Repr {
    fn from(v: F31) -> Self {
        Self { v: v.v as u64 }
    }
}

impl From<u64> for F31Repr {
    fn from(v: u64) -> Self {
        Self { v }
    }
}

impl AsMut<[u64]> for F31Repr {
    fn as_mut(&mut self) -> &mut [u64] {
        unsafe {
            let ptr: *mut u64 = &mut self.v;
            slice::from_raw_parts_mut(ptr, 1)
        }
    }
}

impl Rand for F31Repr {
    fn rand<R: rand::Rng>(rng: &mut R) -> Self {
        let v = rng.gen();
        Self { v }
    }
}

impl Display for F31Repr {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.v)
    }
}

impl AsRef<[u64]> for F31Repr {
    fn as_ref(&self) -> &[u64] {
        unsafe {
            let ptr: *const u64 = &self.v;
            slice::from_raw_parts(ptr, 1)
        }
    }
}

impl PrimeFieldRepr for F31Repr {
    fn sub_noborrow(&mut self, other: &Self) {
        self.v -= other.v;
    }

    fn add_nocarry(&mut self, other: &Self) {
        self.v += other.v;
    }

    fn num_bits(&self) -> u32 {
        64
    }

    fn is_zero(&self) -> bool {
        self.v == 0
    }

    fn is_odd(&self) -> bool {
        self.v % 2 == 1
    }

    fn is_even(&self) -> bool {
        self.v % 2 == 0
    }

    fn div2(&mut self) {
        self.v >>= 1
    }

    fn shr(&mut self, amt: u32) {
        self.v >>= amt
    }

    fn mul2(&mut self) {
        self.v <<= 1
    }

    fn shl(&mut self, amt: u32) {
        self.v <<= amt
    }
}

impl PrimeField for F31 {
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

impl SqrtField for F31 {
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

pub trait Field32: PrimeField {
    fn reduce(el: &u64) -> Self;

    fn to_u32(&self) -> u32;

    fn from_u32(el: u32) -> Self;

    fn from_u64(el: u64) -> Self;

    fn reduce64(x: &mut u64);
}

impl Field32 for F31 {
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
        if *x > Self::FIELD_SIZE as u64 {
            *x -= Self::FIELD_SIZE as u64
        }
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
        let X1 = F31 { v: v1 };
        let X2 = F31 { v: v2 };

        //add and sub test
        let X3 = X1 + X2;
        let X3_check = F31 {
            v: ((v1 as u64 + v2 as u64) % (F31::FIELD_SIZE as u64)) as u32,
        };
        let X4 = X1 - X2;
        let X4_check = F31 {
            v: ((F31::FIELD_SIZE as u64 + v1 as u64 - v2 as u64) % (F31::FIELD_SIZE as u64)) as u32,
        };
        assert_eq!(X3, X3_check);
        assert_eq!(X4, X4_check);

        //mul test
        let X5 = X1 * X2;
        let X5_check = F31 {
            v: (((v1 as u64) * (v2 as u64)) % (F31::FIELD_SIZE as u64)) as u32,
        };
        assert_eq!(X5, X5_check);

        let i = X5.inverse().unwrap();
        assert_eq!(i * X5, F31::one());
    }

    #[test]
    fn test() {
        let mut rng = thread_rng();
        for _ in 0..TESTRUNS {
            let inp1 = F31 {
                v: rng.gen_range::<u32>(0, F31::FIELD_SIZE),
            };
            let inp2 = F31 {
                v: rng.gen_range::<u32>(0, F31::FIELD_SIZE),
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

            assert!(add.v < F31::FIELD_SIZE);
            assert!(sub.v < F31::FIELD_SIZE);
            assert!(mul.v < F31::FIELD_SIZE);
        }
    }
}
