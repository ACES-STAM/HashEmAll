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
pub struct F64 {
    pub v: u64,
}

impl F64 {
    pub const FIELD_SIZE: u64 = 0xFFFFFFFF00000001;
    pub const NUM_BYTES: usize = 8; //number of bytes in the modulus
    pub const D_VALUE: u64 = 7; // min prime such that x^d is a permutation
}

impl Rand for F64 {
    fn rand<R: rand::Rng>(rng: &mut R) -> Self {
        loop {
            let v = rng.gen();
            if v < Self::FIELD_SIZE {
                return Self { v };
            }
        }
    }
}

impl Display for F64 {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.v)
    }
}

impl From<u64> for F64 {
    fn from(v: u64) -> Self {
        Self { v }
    }
}

impl AsMut<[u64]> for F64 {
    fn as_mut(&mut self) -> &mut [u64] {
        unsafe {
            let ptr: *mut u64 = &mut self.v;
            slice::from_raw_parts_mut(ptr, 1)
        }
    }
}

impl AsRef<[u64]> for F64 {
    fn as_ref(&self) -> &[u64] {
        unsafe {
            let ptr: *const u64 = &self.v;
            slice::from_raw_parts(ptr, 1)
        }
    }
}

impl Add for F64 {
    type Output = Self;

    fn add(self, other: F64) -> Self {
        let tmp = (self.v as u128) + (other.v as u128);
        if tmp > Self::FIELD_SIZE as u128 {
            Self {
                v: (tmp - Self::FIELD_SIZE as u128) as u64,
            }
        } else {
            Self { v: tmp as u64 }
        }
    }
}

impl AddAssign<&F64> for F64 {
    fn add_assign(&mut self, other: &F64) {
        let tmp = (self.v as u128) + (other.v as u128);
        if tmp > Self::FIELD_SIZE as u128 {
            self.v = (tmp - Self::FIELD_SIZE as u128) as u64;
        } else {
            self.v = tmp as u64;
        }
    }
}

impl Sub for F64 {
    type Output = Self;

    fn sub(self, other: F64) -> Self {
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

impl SubAssign<&F64> for F64 {
    fn sub_assign(&mut self, other: &F64) {
        if self.v >= other.v {
            self.v -= other.v;
        } else {
            self.v += Self::FIELD_SIZE - other.v;
        }
    }
}

impl Mul for F64 {
    type Output = Self;

    fn mul(self, other: F64) -> Self {
        let x = (self.v as u128) * (other.v as u128);
        Self::reduce(&x)
    }
}

impl MulAssign<&F64> for F64 {
    fn mul_assign(&mut self, other: &F64) {
        let x = (self.v as u128) * (other.v as u128);
        let (x_lo, x_hi) = split(x); // This is a no-op
        let x_hi_hi = x_hi >> 32;
        let x_hi_lo = x_hi & EPSILON;

        let (mut t0, borrow) = x_lo.overflowing_sub(x_hi_hi);
        if borrow {
            branch_hint(); // A borrow is exceedingly rare. It is faster to branch.
            t0 -= EPSILON; // Cannot underflow.
        }
        let t1 = x_hi_lo * EPSILON;
        let t2 = unsafe { add_no_canonicalize_trashing_input(t0, t1) };
        if t2 > Self::FIELD_SIZE {
            branch_hint();
            self.v = t2 - Self::FIELD_SIZE;
        } else {
            self.v = t2;
        }
    }
}

impl Field for F64 {
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
        let mut prev_a = 1i64;
        let mut a = 0i64;
        let mut val = self.v;

        while mod_ != 0 {
            let q = (val / mod_) as i64;
            let mut tmp = (val % mod_) as i64;
            val = mod_;
            mod_ = tmp as u64;

            tmp = a;
            a = prev_a - q.overflowing_mul(a).0;
            prev_a = tmp;
        }
        let mut res = prev_a as u64;
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

impl From<F64> for u64 {
    fn from(v: F64) -> Self {
        v.v
    }
}

impl PrimeFieldRepr for F64 {
    fn sub_noborrow(&mut self, other: &Self) {
        *self = *self - *other;
    }

    fn add_nocarry(&mut self, other: &Self) {
        *self = *self + *other;
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

impl PrimeField for F64 {
    type Repr = F64;

    fn from_repr(repr: Self::Repr) -> Result<Self, ff::PrimeFieldDecodingError> {
        if repr.v > Self::FIELD_SIZE {
            return Err(ff::PrimeFieldDecodingError::NotInField(
                "Not in Field".to_string(),
            ));
        }
        Ok(repr)
    }

    fn from_raw_repr(repr: Self::Repr) -> Result<Self, ff::PrimeFieldDecodingError> {
        Self::from_repr(repr)
    }

    fn into_repr(&self) -> Self::Repr {
        *self
    }

    fn into_raw_repr(&self) -> Self::Repr {
        *self
    }

    fn char() -> Self::Repr {
        Self {
            v: Self::FIELD_SIZE,
        }
    }

    const NUM_BITS: u32 = 64;

    const CAPACITY: u32 = Self::NUM_BITS - 1;

    fn multiplicative_generator() -> Self {
        Self { v: 7 }
    }

    const S: u32 = 32;

    fn root_of_unity() -> Self {
        Self {
            v: 959634606461954525,
        }
    }
}

impl SqrtField for F64 {
    // This impl is kinda cheating :)
    fn legendre(&self) -> ff::LegendreSymbol {
        let s = self.pow([9223372034707292160u64]);
        if s == Self::zero() {
            crate::ff::LegendreSymbol::Zero
        } else if s == Self::one() {
            crate::ff::LegendreSymbol::QuadraticResidue
        } else {
            crate::ff::LegendreSymbol::QuadraticNonResidue
        }
    }

    fn sqrt(&self) -> Option<Self> {
        match self.legendre() {
            crate::ff::LegendreSymbol::Zero => Some(*self),
            crate::ff::LegendreSymbol::QuadraticNonResidue => None,
            crate::ff::LegendreSymbol::QuadraticResidue => {
                let mut c = Self::root_of_unity();
                let mut r = self.pow([2147483648u64]);
                let mut t = self.pow([4294967295u64]);
                let mut m = Self::S;
                while t != Self::one() {
                    let mut i = 1;
                    {
                        let mut t2i = t;
                        t2i.square();
                        loop {
                            if t2i == Self::one() {
                                break;
                            }
                            t2i.square();
                            i += 1;
                        }
                    }
                    for _ in 0..(m - i - 1) {
                        c.square();
                    }
                    r *= &c;
                    c.square();
                    t *= &c;
                    m = i;
                }
                Some(r)
            }
        }
    }
}

pub trait Field64: PrimeField {
    fn reduce(el: &u128) -> Self;

    fn to_u64(&self) -> u64;

    fn from_u64(el: u64) -> Self;

    fn from_u96(el: u128) -> Self;

    fn from_u128(el: u128) -> Self;

    fn reduce96(x: &mut u128);

    fn reduce128(x: &mut u128);
}

#[inline]
pub fn split(x: u128) -> (u64, u64) {
    (x as u64, (x >> 64) as u64)
}

#[inline(always)]
pub fn branch_hint() {
    // NOTE: These are the currently supported assembly architectures. See the
    // [nightly reference](https://doc.rust-lang.org/nightly/reference/inline-assembly.html) for
    // the most up-to-date list.
    #[cfg(any(
        target_arch = "aarch64",
        target_arch = "arm",
        target_arch = "riscv32",
        target_arch = "riscv64",
        target_arch = "x86",
        target_arch = "x86_64",
    ))]
    unsafe {
        core::arch::asm!("", options(nomem, nostack, preserves_flags));
    }
}

/// Fast addition modulo ORDER for x86-64.
/// This function is marked unsafe for the following reasons:
///   - It is only correct if x + y < 2**64 + ORDER = 0x1ffffffff00000001.
///   - It is only faster in some circumstances. In particular, on x86 it overwrites both inputs in
///     the registers, so its use is not recommended when either input will be used again.
///
/// from https://github.com/mir-protocol/plonky2/blob/main/field/src/goldilocks_field.rs
#[cfg(target_arch = "x86_64")]
unsafe fn add_no_canonicalize_trashing_input(x: u64, y: u64) -> u64 {
    let res_wrapped: u64;
    let adjustment: u64;
    core::arch::asm!(
        "add {0}, {1}",
        // Trick. The carry flag is set iff the addition overflowed.
        // sbb x, y does x := x - y - CF. In our case, x and y are both {1:e}, so it simply does
        // {1:e} := 0xffffffff on overflow and {1:e} := 0 otherwise. {1:e} is the low 32 bits of
        // {1}; the high 32-bits are zeroed on write. In the end, we end up with 0xffffffff in {1}
        // on overflow; this happens be EPSILON.
        // Note that the CPU does not realize that the result of sbb x, x does not actually depend
        // on x. We must write the result to a register that we know to be ready. We have a
        // dependency on {1} anyway, so let's use it.
        "sbb {1:e}, {1:e}",
        inlateout(reg) x => res_wrapped,
        inlateout(reg) y => adjustment,
        options(pure, nomem, nostack),
    );
    // assume(x != 0 || (res_wrapped == y && adjustment == 0));
    // assume(y != 0 || (res_wrapped == x && adjustment == 0));
    // Add EPSILON == subtract ORDER.
    // Cannot overflow unless the assumption if x + y < 2**64 + ORDER is incorrect.
    res_wrapped + adjustment
}

#[inline(always)]
#[cfg(not(target_arch = "x86_64"))]
unsafe fn add_no_canonicalize_trashing_input(x: u64, y: u64) -> u64 {
    let (res_wrapped, carry) = x.overflowing_add(y);
    // Below cannot overflow unless the assumption if x + y < 2**64 + ORDER is incorrect.
    res_wrapped + EPSILON * (carry as u64)
}

const EPSILON: u64 = u32::MAX as u64;

impl Field64 for F64 {
    fn reduce(el: &u128) -> Self {
        let (x_lo, x_hi) = split(*el); // This is a no-op
        let x_hi_hi = x_hi >> 32;
        let x_hi_lo = x_hi & EPSILON;

        let (mut t0, borrow) = x_lo.overflowing_sub(x_hi_hi);
        if borrow {
            branch_hint(); // A borrow is exceedingly rare. It is faster to branch.
            t0 -= EPSILON; // Cannot underflow.
        }
        let t1 = x_hi_lo * EPSILON;
        let t2 = unsafe { add_no_canonicalize_trashing_input(t0, t1) };
        if t2 > Self::FIELD_SIZE {
            branch_hint();
            Self {
                v: t2 - Self::FIELD_SIZE,
            }
        } else {
            Self { v: t2 }
        }
    }

    fn to_u64(&self) -> u64 {
        self.v
    }

    fn from_u64(x: u64) -> Self {
        debug_assert!(x < Self::FIELD_SIZE);
        Self { v: x }
    }

    fn from_u96(x: u128) -> Self {
        let (x_lo, x_hi_lo) = split(x); // This is a no-op
        let t1 = x_hi_lo * EPSILON;
        let t2 = unsafe { add_no_canonicalize_trashing_input(x_lo, t1) };
        if t2 > Self::FIELD_SIZE {
            branch_hint();
            Self {
                v: t2 - Self::FIELD_SIZE,
            }
        } else {
            Self { v: t2 }
        }
    }

    fn from_u128(x: u128) -> Self {
        Self::reduce(&x)
    }

    fn reduce96(x: &mut u128) {
        let (x_lo, x_hi_lo) = split(*x); // This is a no-op
        let t1 = x_hi_lo * EPSILON;
        *x = unsafe { add_no_canonicalize_trashing_input(x_lo, t1) } as u128;
    }

    fn reduce128(x: &mut u128) {
        let (x_lo, x_hi) = split(*x); // This is a no-op
        let x_hi_hi = x_hi >> 32;
        let x_hi_lo = x_hi & EPSILON;

        let (mut t0, borrow) = x_lo.overflowing_sub(x_hi_hi);
        if borrow {
            branch_hint(); // A borrow is exceedingly rare. It is faster to branch.
            t0 -= EPSILON; // Cannot underflow.
        }
        let t1 = x_hi_lo * EPSILON;
        *x = unsafe { add_no_canonicalize_trashing_input(t0, t1) } as u128;

        if *x > Self::FIELD_SIZE as u128 {
            branch_hint();
            *x -= Self::FIELD_SIZE as u128;
        }
    }
}

#[cfg(test)]
mod f64_field_test {
    use super::*;

    use rand::{thread_rng, Rng};
    static TESTRUNS: usize = 5;

    #[allow(non_snake_case)]
    #[test]
    fn kats() {
        let v1 = 0xFFFFFF00000001_u64; // 0xFFFFFF00000001 as u64;
        let v2 = 0xFFFFFFFF00000000_u64; //0xFFFFFFFF00000000 as u64;
        let X1 = F64 { v: v1 };
        let X2 = F64 { v: v2 };

        //add and sub test
        let X3 = X1 + X2;
        let X3_check = F64 {
            v: ((v1 as u128 + v2 as u128) % (F64::FIELD_SIZE as u128)) as u64,
        };
        let X4 = X1 - X2;
        let X4_check = F64 {
            v: ((F64::FIELD_SIZE as u128 + v1 as u128 - v2 as u128) % (F64::FIELD_SIZE as u128))
                as u64,
        };
        assert_eq!(X3, X3_check);
        assert_eq!(X4, X4_check);

        //mul test
        let X5 = X1 * X2;
        let X5_check = F64 {
            v: (((v1 as u128) * (v2 as u128)) % (F64::FIELD_SIZE as u128)) as u64,
        };
        assert_eq!(X5, X5_check);

        let i = X5.inverse().unwrap();
        assert_eq!(i * X5, F64::one());
    }

    #[test]
    fn test() {
        let mut rng = thread_rng();
        for _ in 0..TESTRUNS {
            let inp1 = F64 {
                v: rng.gen_range::<u64>(0, F64::FIELD_SIZE),
            };
            let inp2 = F64 {
                v: rng.gen_range::<u64>(0, F64::FIELD_SIZE),
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

            assert!(add.v < F64::FIELD_SIZE);
            assert!(sub.v < F64::FIELD_SIZE);
            assert!(mul.v < F64::FIELD_SIZE);
        }
    }
}
