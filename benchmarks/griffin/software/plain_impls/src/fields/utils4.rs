use std::cmp::min;

use ff::{PrimeField, PrimeFieldDecodingError};
use rand::{thread_rng, Rng};
use sha3::digest::XofReader;

//-----------------------------------------------------------------------------
pub fn from_u64<F: PrimeField>(val: u64) -> F {
    F::from_repr(F::Repr::from(val)).unwrap()
}

pub fn random_scalar_rng<F: PrimeField, R: Rng>(allow_zero: bool, rng: &mut R) -> F {
    loop {
        let s = F::rand(rng);
        if allow_zero || s != F::zero() {
            return s;
        }
    }
}

pub fn random_scalar<F: PrimeField>(allow_zero: bool) -> F {
    loop {
        let s = F::rand(&mut thread_rng());
        if allow_zero || s != F::zero() {
            return s;
        }
    }
}

pub fn into_limbs<F: PrimeField>(val: &F) -> [u64; 4] {
    let mut res = [0u64; 4];
    res.copy_from_slice(val.into_repr().as_ref());
    res
}

pub fn from_limbs<F: PrimeField>(repr: &[u64; 4]) -> F {
    let mut tmp = F::Repr::default();
    tmp.as_mut().copy_from_slice(repr);
    F::from_repr(tmp).unwrap()
}

fn from_limbs_with_error<F: PrimeField>(repr: &[u64; 4]) -> Result<F, PrimeFieldDecodingError> {
    let mut tmp = F::Repr::default();
    tmp.as_mut().copy_from_slice(repr);
    F::from_repr(tmp)
}

pub fn field_element_from_shake<F: PrimeField>(reader: &mut dyn XofReader) -> F {
    let bytes = f64::ceil(F::NUM_BITS as f64 / 8f64) as usize;
    let mod_ = F::NUM_BITS % 8;
    let mask = if mod_ == 0 { 0xFF } else { (1u8 << mod_) - 1 };
    let mut buf = vec![0u8; bytes];
    let mut word_buf = [0u64; 4];

    let len = buf.len();
    loop {
        reader.read(&mut buf);
        buf[len - 1] &= mask;
        for i in 0..4 {
            let mut byte_array = [0u8; 8];
            for j in i * 8..min((i + 1) * 8, len) {
                byte_array[j - i * 8] = buf[j];
            }
            word_buf[i] = u64::from_le_bytes(byte_array);
        }
        let res = from_limbs_with_error::<F>(&word_buf);
        if let Ok(el) = res {
            return el;
        }
    }
}

// -----------------------------------------------------------------------------
// Modified Crandall algorithm
// https://ece.uwaterloo.ca/~ahasan/web_papers/technical_reports/web_lwpfi.pdf
//-----------------------------------------------------------------------------

#[inline(always)]
const fn is_zero(a: &[u64; 4]) -> bool {
    if a[0] != 0 {
        return false;
    }
    if a[1] != 0 {
        return false;
    }
    if a[2] != 0 {
        return false;
    }
    if a[3] != 0 {
        return false;
    }
    true
}

#[inline(always)]
pub const fn partial_add(a: &[u64; 4], b: &[u64; 4]) -> [u64; 4] {
    let mut res = [0; 4];
    let (tmp, o) = a[0].overflowing_add(b[0]);
    res[0] = tmp;
    let mut carry: u64 = o as u64;

    let (tmp, o1) = (a[1]).overflowing_add(b[1]);
    let (tmp, o2) = tmp.overflowing_add(carry);
    res[1] = tmp;
    carry = (o1 as u64) + (o2 as u64);

    let (tmp, o1) = (a[2]).overflowing_add(b[2]);
    let (tmp, o2) = tmp.overflowing_add(carry);
    res[2] = tmp;
    carry = (o1 as u64) + (o2 as u64);

    let (tmp, _) = (a[3]).overflowing_add(b[3]);
    let (tmp, _) = tmp.overflowing_add(carry);
    res[3] = tmp;
    res
}

#[inline(always)]
pub const fn div_mod_crandall(a: &[u64; 4], k: u32) -> ([u64; 4], u16) {
    let mask = (1u64 << k) - 1;

    let mut ri = a[0] & mask;
    let mut qi = full_shr(a, k);

    let mut q = qi;
    let mut r = ri;

    while !is_zero(&qi) {
        ri = qi[0] & mask;
        qi = full_shr(&qi, k);
        q = partial_add(&q, &qi);
        r += ri;
    }

    let mut add = 0;
    while r >= mask {
        r -= mask;
        add += 1;
    }
    if add != 0 {
        q = add_single_word(&q, add);
    }
    (q, r as u16)
}

// -----------------------------------------------------------------------------
// mgdiv by 1023
//-----------------------------------------------------------------------------

const fn combine_to_u128(lo: u64, hi: u64) -> u128 {
    ((hi as u128) << 64) | (lo as u128)
}

const fn umul(a: u64, b: u64) -> u128 {
    (a as u128) * (b as u128)
}

fn divrem_2by1_mg(u0: u64, u1: u64, d: u64, v: u64) -> (u64, u64) {
    debug_assert!(d >= 1_u64 << 63);
    debug_assert!(u1 < d);
    let mut q = ((umul(v, u1) >> 64) as u64) + u1;
    let p = umul(q, d);
    let mut r = combine_to_u128(u0, u1) - p;
    if r >= (d as u128) {
        q += 1;
        r -= d as u128;
    }
    if r >= (d as u128) {
        q += 1;
        r -= d as u128;
    }
    if r >= (d as u128) {
        q += 1;
        r -= d as u128;
    }
    debug_assert!(r >> 64 == 0);
    let r = r as u64;
    debug_assert!(r < d);
    debug_assert_eq!(combine_to_u128(u0, u1), umul(q, d) + (r as u128));
    (q, r)
}

fn divrem_2by1(lo: u64, hi: u64) -> (u64, u64) {
    const D: u64 = 1023;
    const R: u64 = 0x0040100401004010; // Floor(2^64 / D)
    let d = D << 54;
    let v = R;
    let u1 = (hi << 54) | (lo >> 10);
    let u0 = lo << 54;

    let (q, mut r) = divrem_2by1_mg(u0, u1, d, v);

    r >>= 54;
    (q, r)
}

#[inline(always)]
pub fn div1023(numerator: &[u64; 4]) -> ([u64; 4], u16) {
    let remainder = 0;
    let mut res = [0u64; 4];
    let (ni, remainder) = divrem_2by1(numerator[3], remainder);
    res[3] = ni;
    let (ni, remainder) = divrem_2by1(numerator[2], remainder);
    res[2] = ni;
    let (ni, remainder) = divrem_2by1(numerator[1], remainder);
    res[1] = ni;
    let (ni, remainder) = divrem_2by1(numerator[0], remainder);
    res[0] = ni;
    (res, remainder as u16)
}

// -----------------------------------------------------------------------------
// standard division
//-----------------------------------------------------------------------------

#[inline(always)]
const fn div_mod_word_by_short(hi: u64, lo: u64, y: u16) -> (u64, u64) {
    let t = ((hi as u128) << 64) + lo as u128;
    let q = (t / (y as u128)) as u64;
    let r = (t % (y as u128)) as u64;

    (q, r)
}

#[inline(always)]
pub fn divide_long_decomp(a: &[u64; 4], divisor: u16, offset: &mut usize) -> ([u64; 4], u16) {
    let mut result = [0u64; 4];

    let mut start_index = 3 - *offset;

    // optimize for decomposition
    if a[start_index] == 0 {
        *offset += 1;
        start_index -= 1;
    }

    result[start_index] = a[start_index] / (divisor as u64);
    let mut r = a[start_index] % (divisor as u64);

    result
        .iter_mut()
        .zip(a.iter())
        .rev()
        .skip(*offset + 1)
        .for_each(|(res, a_)| {
            let (q, m) = div_mod_word_by_short(r, *a_, divisor);
            *res = q;
            r = m;
        });

    (result, r as u16)
}

#[inline(always)]
pub const fn divide_long(a: &[u64; 4], divisor: u16) -> ([u64; 4], u16) {
    let mut result = [0u64; 4];
    result[3] = a[3] / (divisor as u64);
    let r = a[3] % (divisor as u64);
    let (q, r) = div_mod_word_by_short(r, a[2], divisor);
    result[2] = q;
    let (q, r) = div_mod_word_by_short(r, a[1], divisor);
    result[1] = q;
    let (q, r) = div_mod_word_by_short(r, a[0], divisor);
    result[0] = q;

    (result, r as u16)
}

// -----------------------------------------------------------------------------
// Division with precomputation
//-----------------------------------------------------------------------------

pub const fn compute_normalized_divisor_and_reciproical(input: u16) -> (u64, u64) {
    let s = (input as u64).leading_zeros();
    let normalized_divisor = (input as u64) << s;
    let reciproical = u128::MAX / (normalized_divisor as u128) - (1u128 << 64);

    (normalized_divisor, reciproical as u64)
}

#[inline(always)]
const fn split(a: u128) -> (u64, u64) {
    ((a >> 64) as u64, a as u64)
}

#[inline(always)]
const fn div_mod_word_by_short_normalized(
    u1: u64,
    u0: u64,
    divisor: u64,
    recip: u64,
) -> (u64, u64) {
    let qq = (u1 as u128) * (recip as u128);
    let qq = qq + ((u1 as u128) << 64) + (u0 as u128);
    let (q1, q0) = split(qq);
    let mut q1 = q1.wrapping_add(1u64);
    let mut r = u0.wrapping_sub(q1.wrapping_mul(divisor));
    if r > q0 {
        q1 = q1.wrapping_sub(1u64);
        r = r.wrapping_add(divisor);
    }
    if r >= divisor {
        q1 += 1;
        r -= divisor;
    }

    (q1, r)
}

#[inline(always)]
pub const fn divide_long_using_recip(
    a: &[u64; 4],
    divisor: u64,
    recip: u64,
    norm_shift: u32,
) -> ([u64; 4], u16) {
    let mut result = [0u64; 4];
    let (shifted, o) = full_shl(a, norm_shift);
    let (q, r) = div_mod_word_by_short_normalized(o, shifted[3], divisor, recip);
    result[3] = q;

    let (q, r) = div_mod_word_by_short_normalized(r, shifted[2], divisor, recip);
    result[2] = q;

    let (q, r) = div_mod_word_by_short_normalized(r, shifted[1], divisor, recip);
    result[1] = q;

    let (q, r) = div_mod_word_by_short_normalized(r, shifted[0], divisor, recip);
    result[0] = q;

    (result, (r >> norm_shift) as u16)
}

// -----------------------------------------------------------------------------

#[inline(always)]
pub const fn add_single_word(u: &[u64; 4], w: u64) -> [u64; 4] {
    let mut res = [0u64; 4];
    let (tmp, of) = u[0].overflowing_add(w);
    res[0] = tmp;
    let (tmp, of) = u[1].overflowing_add(of as u64);
    res[1] = tmp;
    let (tmp, of) = u[2].overflowing_add(of as u64);
    res[2] = tmp;

    res[3] = u[3].wrapping_add(of as u64);

    res
}

// -----------------------------------------------------------------------------

#[inline(always)]
pub const fn mul_by_single_word(u: &[u64; 4], w: u64) -> [u64; 4] {
    let mut res = [0u64; 4];
    let tmp = (u[0] as u128) * (w as u128);
    res[0] = tmp as u64;
    let tmp = (u[1] as u128) * (w as u128) + (tmp >> 64);
    res[1] = tmp as u64;
    let tmp = (u[2] as u128) * (w as u128) + (tmp >> 64);
    res[2] = tmp as u64;
    let tmp = (u[3] as u128) * (w as u128) + (tmp >> 64);
    res[3] = tmp as u64;

    res
}

// -----------------------------------------------------------------------------

#[inline(always)]
pub const fn full_shr(u: &[u64; 4], shift: u32) -> [u64; 4] {
    // assert!(shift <= 64u32);

    let mut res = [0u64; 4];
    let shift_high: u32 = 64u32 - shift;

    res[0] = u[0] >> shift;
    res[1] = u[1] >> shift;
    res[2] = u[2] >> shift;
    res[3] = u[3] >> shift;

    res[0] |= u[1] << shift_high;
    res[1] |= u[2] << shift_high;
    res[2] |= u[3] << shift_high;

    res
}

#[inline(always)]
pub const fn full_shl(u: &[u64; 4], shift: u32) -> ([u64; 4], u64) {
    // assert!(shift <= 64u32);

    let mut res = [0u64; 4];
    let shift_high: u32 = 64u32 - shift;

    res[1] = u[0] >> shift_high;
    res[2] = u[1] >> shift_high;
    res[3] = u[2] >> shift_high;

    res[0] = u[0] << shift;
    res[1] |= u[1] << shift;
    res[2] |= u[2] << shift;
    res[3] |= u[3] << shift;

    (res, u[3] >> shift_high)
}

#[inline(always)]
pub const fn partial_shl(u: &[u64; 4], shift: u32) -> [u64; 4] {
    // assert!(shift <= 64u32);

    let mut res = [0u64; 4];
    let shift_high: u32 = 64u32 - shift;

    res[1] = u[0] >> shift_high;
    res[2] = u[1] >> shift_high;
    res[3] = u[2] >> shift_high;

    res[0] = u[0] << shift;
    res[1] |= u[1] << shift;
    res[2] |= u[2] << shift;
    res[3] |= u[3] << shift;

    res
}

#[cfg(test)]
mod utils_test_bls12 {
    use ff::{to_hex, Field};

    use super::*;
    use crate::fields::bls12::FpBLS12;

    static TESTRUNS: usize = 5;

    type Scalar = FpBLS12;

    #[test]
    fn random() {
        let rands: Vec<Scalar> = (0..TESTRUNS).map(|_| random_scalar(true)).collect();
        for i in 0..TESTRUNS {
            for j in i + 1..TESTRUNS {
                assert_ne!(rands[i], rands[j]);
            }
        }
    }

    #[test]
    fn from_u64() {
        let ten = super::from_u64::<Scalar>(10);
        assert_eq!(
            to_hex(&ten),
            "000000000000000000000000000000000000000000000000000000000000000a"
        )
    }

    #[test]
    fn limbs() {
        let ten = super::from_u64::<Scalar>(10);
        let ten_limbs = [10, 0, 0, 0];
        assert_eq!(into_limbs::<Scalar>(&ten), ten_limbs);
        assert_eq!(ten, from_limbs::<Scalar>(&ten_limbs));
        let input: Scalar = random_scalar(true);

        for _ in 0..TESTRUNS {
            assert_eq!(input, from_limbs::<Scalar>(&into_limbs::<Scalar>(&input)));
        }
    }

    #[test]
    fn div_mod_multiply_add() {
        let mut rng = thread_rng();

        // KAT
        let ten = super::from_u64::<Scalar>(10);
        let ten_repr = into_limbs(&ten);
        let div = 3;

        let (res, m) = divide_long(&ten_repr, div);

        assert_eq!(m, 1);
        assert_eq!(
            to_hex::<Scalar>(&from_limbs(&res)),
            "0000000000000000000000000000000000000000000000000000000000000003"
        );

        let tmp = mul_by_single_word(&res, div as u64);
        let tmp = add_single_word(&tmp, m as u64);
        assert_eq!(from_limbs::<Scalar>(&tmp), ten);

        let mut res: Scalar = from_limbs(&res);
        let div = super::from_u64::<Scalar>(div as u64);
        let m = super::from_u64::<Scalar>(m as u64);

        res.mul_assign(&div);
        res.add_assign(&m);

        assert_eq!(ten, res);

        // rand tests
        for _ in 0..TESTRUNS {
            let input: Scalar = random_scalar_rng(true, &mut rng);
            let mut div = rng.gen::<u16>();
            if div == 0 {
                div = 1;
            }
            let (res, m) = divide_long(&into_limbs(&input), div);

            let tmp = mul_by_single_word(&res, div as u64);
            let tmp = add_single_word(&tmp, m as u64);
            assert_eq!(from_limbs::<Scalar>(&tmp), input);
        }
    }

    #[test]
    fn div_equal() {
        let bit: u16 = 10;
        let div = (1 << bit) - 1;

        let (divisor, recip) = compute_normalized_divisor_and_reciproical(div);
        let s = (div as u64).leading_zeros();

        for _ in 0..TESTRUNS {
            let input: Scalar = random_scalar(true);
            let repr = into_limbs(&input);
            let (res1, m1) = divide_long(&repr, div);
            let (res2, m2) = divide_long_using_recip(&repr, divisor, recip, s);
            let (res3, m3) = div_mod_crandall(&repr, bit as u32);

            assert_eq!(res1, res2);
            assert_eq!(res1, res3);
            assert_eq!(m1, m2);
            assert_eq!(m1, m3);
        }
    }
}

#[cfg(test)]
mod utils_test_bn256 {
    use ff::{to_hex, Field};

    use super::*;
    use crate::fields::bn256::FpBN256;

    static TESTRUNS: usize = 5;

    type Scalar = FpBN256;

    #[test]
    fn random() {
        let rands: Vec<Scalar> = (0..TESTRUNS).map(|_| random_scalar(true)).collect();
        for i in 0..TESTRUNS {
            for j in i + 1..TESTRUNS {
                assert_ne!(rands[i], rands[j]);
            }
        }
    }

    #[test]
    fn from_u64() {
        let ten = super::from_u64::<Scalar>(10);
        assert_eq!(
            to_hex(&ten),
            "000000000000000000000000000000000000000000000000000000000000000a"
        )
    }

    #[test]
    fn limbs() {
        let ten = super::from_u64::<Scalar>(10);
        let ten_limbs = [10, 0, 0, 0];
        assert_eq!(into_limbs::<Scalar>(&ten), ten_limbs);
        assert_eq!(ten, from_limbs::<Scalar>(&ten_limbs));
        let input: Scalar = random_scalar(true);

        for _ in 0..TESTRUNS {
            assert_eq!(input, from_limbs::<Scalar>(&into_limbs::<Scalar>(&input)));
        }
    }

    #[test]
    fn div_mod_multiply_add() {
        let mut rng = thread_rng();

        // KAT
        let ten = super::from_u64::<Scalar>(10);
        let ten_repr = into_limbs(&ten);
        let div = 3;

        let (res, m) = divide_long(&ten_repr, div);

        assert_eq!(m, 1);
        assert_eq!(
            to_hex::<Scalar>(&from_limbs(&res)),
            "0000000000000000000000000000000000000000000000000000000000000003"
        );

        let tmp = mul_by_single_word(&res, div as u64);
        let tmp = add_single_word(&tmp, m as u64);
        assert_eq!(from_limbs::<Scalar>(&tmp), ten);

        let mut res: Scalar = from_limbs(&res);
        let div = super::from_u64::<Scalar>(div as u64);
        let m = super::from_u64::<Scalar>(m as u64);

        res.mul_assign(&div);
        res.add_assign(&m);

        assert_eq!(ten, res);

        // rand tests
        for _ in 0..TESTRUNS {
            let input: Scalar = random_scalar_rng(true, &mut rng);
            let mut div = rng.gen::<u16>();
            if div == 0 {
                div = 1;
            }
            let (res, m) = divide_long(&into_limbs(&input), div);

            let tmp = mul_by_single_word(&res, div as u64);
            let tmp = add_single_word(&tmp, m as u64);
            assert_eq!(from_limbs::<Scalar>(&tmp), input);
        }
    }

    #[test]
    fn div_equal() {
        let bit: u16 = 10;
        let div = (1 << bit) - 1;

        let (divisor, recip) = compute_normalized_divisor_and_reciproical(div);
        let s = (div as u64).leading_zeros();

        for _ in 0..TESTRUNS {
            let input: Scalar = random_scalar(true);
            let repr = into_limbs(&input);
            let (res1, m1) = divide_long(&repr, div);
            let (res2, m2) = divide_long_using_recip(&repr, divisor, recip, s);
            let (res3, m3) = div_mod_crandall(&repr, bit as u32);

            assert_eq!(res1, res2);
            assert_eq!(res1, res3);
            assert_eq!(m1, m2);
            assert_eq!(m1, m3);
        }
    }
}

#[cfg(test)]
mod utils_test_st {
    use ff::{to_hex, Field};

    use super::*;
    use crate::fields::st::FpST;

    static TESTRUNS: usize = 5;

    type Scalar = FpST;

    #[test]
    fn random() {
        let rands: Vec<Scalar> = (0..TESTRUNS).map(|_| random_scalar(true)).collect();
        for i in 0..TESTRUNS {
            for j in i + 1..TESTRUNS {
                assert_ne!(rands[i], rands[j]);
            }
        }
    }

    #[test]
    fn from_u64() {
        let ten = super::from_u64::<Scalar>(10);
        assert_eq!(
            to_hex(&ten),
            "000000000000000000000000000000000000000000000000000000000000000a"
        )
    }

    #[test]
    fn limbs() {
        let ten = super::from_u64::<Scalar>(10);
        let ten_limbs = [10, 0, 0, 0];
        assert_eq!(into_limbs::<Scalar>(&ten), ten_limbs);
        assert_eq!(ten, from_limbs::<Scalar>(&ten_limbs));
        let input: Scalar = random_scalar(true);

        for _ in 0..TESTRUNS {
            assert_eq!(input, from_limbs::<Scalar>(&into_limbs::<Scalar>(&input)));
        }
    }

    #[test]
    fn div_mod_multiply_add() {
        let mut rng = thread_rng();

        // KAT
        let ten = super::from_u64::<Scalar>(10);
        let ten_repr = into_limbs(&ten);
        let div = 3;

        let (res, m) = divide_long(&ten_repr, div);

        assert_eq!(m, 1);
        assert_eq!(
            to_hex::<Scalar>(&from_limbs(&res)),
            "0000000000000000000000000000000000000000000000000000000000000003"
        );

        let tmp = mul_by_single_word(&res, div as u64);
        let tmp = add_single_word(&tmp, m as u64);
        assert_eq!(from_limbs::<Scalar>(&tmp), ten);

        let mut res: Scalar = from_limbs(&res);
        let div = super::from_u64::<Scalar>(div as u64);
        let m = super::from_u64::<Scalar>(m as u64);

        res.mul_assign(&div);
        res.add_assign(&m);

        assert_eq!(ten, res);

        // rand tests
        for _ in 0..TESTRUNS {
            let input: Scalar = random_scalar_rng(true, &mut rng);
            let mut div = rng.gen::<u16>();
            if div == 0 {
                div = 1;
            }
            let (res, m) = divide_long(&into_limbs(&input), div);

            let tmp = mul_by_single_word(&res, div as u64);
            let tmp = add_single_word(&tmp, m as u64);
            assert_eq!(from_limbs::<Scalar>(&tmp), input);
        }
    }

    #[test]
    fn div_equal() {
        let bit: u16 = 10;
        let div = (1 << bit) - 1;

        let (divisor, recip) = compute_normalized_divisor_and_reciproical(div);
        let s = (div as u64).leading_zeros();

        for _ in 0..TESTRUNS {
            let input: Scalar = random_scalar(true);
            let repr = into_limbs(&input);
            let (res1, m1) = divide_long(&repr, div);
            let (res2, m2) = divide_long_using_recip(&repr, divisor, recip, s);
            let (res3, m3) = div_mod_crandall(&repr, bit as u32);

            assert_eq!(res1, res2);
            assert_eq!(res1, res3);
            assert_eq!(m1, m2);
            assert_eq!(m1, m3);
        }
    }
}
