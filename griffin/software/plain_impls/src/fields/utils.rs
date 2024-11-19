use ff::{PrimeField, PrimeFieldDecodingError, PrimeFieldRepr};
use rand::{thread_rng, Rng, SeedableRng, StdRng};
use sha3::digest::XofReader;
use std::cmp::min;

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

pub fn random_scalar_with_seed<F: PrimeField>(allow_zero: bool, seed: &[usize]) -> F {
    loop {
        let s = F::rand(&mut StdRng::from_seed(seed));
        if allow_zero || s != F::zero() {
            return s;
        }
    }
}

pub fn into_limbs<F: PrimeField>(val: &F) -> Vec<u64> {
    val.into_repr().as_ref().to_owned()
}

pub fn from_limbs<F: PrimeField>(repr: &[u64]) -> F {
    let mut tmp = F::Repr::default();
    tmp.as_mut().copy_from_slice(repr);
    F::from_repr(tmp).unwrap()
}

fn from_limbs_with_error<F: PrimeField>(repr: &[u64]) -> Result<F, PrimeFieldDecodingError> {
    let mut tmp = F::Repr::default();
    tmp.as_mut().copy_from_slice(repr);
    F::from_repr(tmp)
}

pub fn field_element_from_shake<F: PrimeField>(reader: &mut dyn XofReader) -> F {
    let bytes = f64::ceil(F::NUM_BITS as f64 / 8f64) as usize;
    let words = f64::ceil(bytes as f64 / 8f64) as usize;
    let mod_ = F::NUM_BITS % 8;
    let mask = if mod_ == 0 { 0xFF } else { (1u8 << mod_) - 1 };
    let mut buf = vec![0u8; bytes];
    let mut word_buf = vec![0u64; words];

    let len = buf.len();
    loop {
        reader.read(&mut buf);
        buf[len - 1] &= mask;
        for i in 0..words {
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

pub fn field_element_from_shake_without_0<F: PrimeField>(reader: &mut dyn XofReader) -> F {
    loop {
        let element = field_element_from_shake::<F>(reader);
        if !element.is_zero() {
            return element;
        }
    }
}

// -----------------------------------------------------------------------------
// Modified Crandall algorithm
// https://ece.uwaterloo.ca/~ahasan/web_papers/technical_reports/web_lwpfi.pdf
//-----------------------------------------------------------------------------

#[inline(always)]
fn is_zero<F: PrimeField>(a: &F::Repr) -> bool {
    for a_ in a.as_ref().iter() {
        if *a_ != 0 {
            return false;
        }
    }
    true
}

#[inline(always)]
pub fn partial_add_inplace<F: PrimeField>(a: &mut F::Repr, b: &F::Repr) {
    let a_mut = a.as_mut();
    let b_ref = b.as_ref();

    let (tmp, o) = a_mut[0].overflowing_add(b_ref[0]);
    a_mut[0] = tmp;
    let mut carry: u64 = o as u64;

    a_mut
        .iter_mut()
        .zip(b_ref.iter())
        .skip(1)
        .for_each(|(a_, b_)| {
            let (tmp, o1) = (*a_).overflowing_add(*b_);
            let (tmp, o2) = tmp.overflowing_add(carry);
            *a_ = tmp;
            carry = (o1 as u64) + (o2 as u64);
        });
}

#[inline(always)]
pub fn div_mod_crandall<F: PrimeField>(a: &F::Repr, k: u32) -> (F::Repr, u16) {
    let mask = (1u64 << k) - 1;

    let mut ri = a.as_ref()[0] & mask;
    let mut qi = full_shr::<F>(a, k);

    let mut q = qi;
    let mut r = ri;

    while !is_zero::<F>(&qi) {
        ri = qi.as_ref()[0] & mask;
        qi = full_shr::<F>(&qi, k);
        partial_add_inplace::<F>(&mut q, &qi);
        r += ri;
    }

    let mut add = 0;
    while r >= mask {
        r -= mask;
        add += 1;
    }
    if add != 0 {
        q = add_single_word::<F>(&q, add);
    }
    (q, r as u16)
}

// -----------------------------------------------------------------------------
// standard division
//-----------------------------------------------------------------------------

#[inline(always)]
fn div_mod_word_by_short(hi: u64, lo: u64, y: u16) -> (u64, u64) {
    let t = ((hi as u128) << 64) + lo as u128;
    let q = (t / (y as u128)) as u64;
    let r = (t % (y as u128)) as u64;

    (q, r)
}

#[inline(always)]
pub fn divide_long_decomp<F: PrimeField>(
    a: &F::Repr,
    divisor: u16,
    offset: &mut usize,
) -> (F::Repr, u16) {
    let mut result = F::Repr::default();

    let a_ref = a.as_ref();
    let result_mut = result.as_mut();

    let len = a_ref.len();
    let mut start_index = len - *offset - 1;

    // optimize for decomposition
    if a_ref[start_index] == 0 {
        *offset += 1;
        start_index -= 1;
    }

    result_mut[start_index] = a_ref[start_index] / (divisor as u64);
    let mut r = a_ref[start_index] % (divisor as u64);

    result_mut
        .iter_mut()
        .zip(a_ref.iter())
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
pub fn divide_long<F: PrimeField>(a: &F::Repr, divisor: u16) -> (F::Repr, u16) {
    let mut result = F::Repr::default();

    let a_ref = a.as_ref();
    let result_mut = result.as_mut();

    let len = a_ref.len();

    result_mut[len - 1] = a_ref[len - 1] / (divisor as u64);
    let mut r = a.as_ref()[len - 1] % (divisor as u64);

    result_mut
        .iter_mut()
        .zip(a_ref.iter())
        .rev()
        .skip(1)
        .for_each(|(res, a_)| {
            let (q, m) = div_mod_word_by_short(r, *a_, divisor);
            *res = q;
            r = m;
        });

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
pub fn divide_long_using_recip<F: PrimeField>(
    a: &F::Repr,
    divisor: u64,
    recip: u64,
    norm_shift: u32,
) -> (F::Repr, u16) {
    let mut result = F::Repr::default();
    let (repr, mut limb) = full_shl::<F>(a, norm_shift);

    result
        .as_mut()
        .iter_mut()
        .zip(repr.as_ref().iter())
        .rev()
        .for_each(|(r, rep)| {
            let (q, m) = div_mod_word_by_short_normalized(limb, *rep, divisor, recip);
            *r = q;
            limb = m;
        });

    (result, (limb >> norm_shift) as u16)
}

// -----------------------------------------------------------------------------

#[inline(always)]
pub fn add_single_word<F: PrimeField>(u: &F::Repr, w: u64) -> F::Repr {
    let mut res = F::Repr::default();

    let u_ref = u.as_ref();
    let res_mut = res.as_mut();

    let len = res_mut.len();

    let mut of = w;
    for index in 0..len - 1 {
        let (tmp, o) = u_ref[index].overflowing_add(of);
        res_mut[index] = tmp;
        of = o as u64;
    }

    res_mut[len - 1] = u_ref[len - 1].wrapping_add(of);
    res
}

// -----------------------------------------------------------------------------

#[inline(always)]
pub fn mul_by_single_word<F: PrimeField>(u: &F::Repr, w: u64) -> F::Repr {
    let mut res = F::Repr::default();

    let u_ref = u.as_ref();
    let res_mut = res.as_mut();

    let w_ = w as u128;

    let mut tmp = (u_ref[0] as u128) * w_;
    res_mut[0] = tmp as u64;
    res_mut
        .iter_mut()
        .zip(u_ref.iter())
        .skip(1)
        .for_each(|(r, u_)| {
            tmp = (*u_ as u128) * w_ + (tmp >> 64);
            *r = tmp as u64;
        });
    res
}

pub fn mul_by_single_word_carry<F: PrimeField>(u: &F::Repr, w: u64) -> (F::Repr, u64) {
    let mut res = F::Repr::default();

    let u_ref = u.as_ref();
    let res_mut = res.as_mut();

    let w_ = w as u128;

    let mut tmp = (u_ref[0] as u128) * w_;
    res_mut[0] = tmp as u64;
    res_mut
        .iter_mut()
        .zip(u_ref.iter())
        .skip(1)
        .for_each(|(r, u_)| {
            tmp = (*u_ as u128) * w_ + (tmp >> 64);
            *r = tmp as u64;
        });
    (res, (tmp >> 64) as u64)
}

// -----------------------------------------------------------------------------

#[inline(always)]
pub fn full_shr<F: PrimeField>(u: &F::Repr, shift: u32) -> F::Repr {
    assert!(shift <= 64u32);
    let mut res = F::Repr::default();

    let u_ref = u.as_ref();
    let res_mut = res.as_mut();

    let len = res_mut.len();

    res_mut
        .iter_mut()
        .zip(u_ref.iter())
        .for_each(|(r, u_)| *r = *u_ >> shift);

    for index in 0..len - 1 {
        res_mut[index] |= u_ref[index + 1] << (64u32 - shift);
    }
    res
}

#[inline(always)]
pub fn full_shl<F: PrimeField>(u: &F::Repr, shift: u32) -> (F::Repr, u64) {
    assert!(shift <= 64u32);
    let mut res = F::Repr::default();

    let u_ref = u.as_ref();
    let res_mut = res.as_mut();

    let len = res_mut.len();

    for index in 0..len - 1 {
        res_mut[index + 1] = u_ref[index] >> (64u32 - shift);
    }

    res_mut.iter_mut().zip(u_ref.iter()).for_each(|(r, u_)| {
        *r |= *u_ << shift;
    });

    // adds a limb
    (res, u_ref[len - 1] >> (64u32 - shift))
}

#[inline(always)]
pub fn partial_shl<F: PrimeField>(u: &F::Repr, shift: u32) -> F::Repr {
    assert!(shift <= 64u32);
    let mut res = F::Repr::default();

    let u_ref = u.as_ref();
    let res_mut = res.as_mut();

    let len = res_mut.len();

    for index in 0..len - 1 {
        res_mut[index + 1] = u_ref[index] >> (64u32 - shift);
    }

    res_mut
        .iter_mut()
        .zip(u_ref.iter())
        .for_each(|(r, u_)| *r |= *u_ << shift);
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
        let ten_repr = ten.into_repr();
        let div = 3;

        let (res, m) = divide_long::<Scalar>(&ten_repr, div);

        assert_eq!(m, 1);
        assert_eq!(
            to_hex(&Scalar::from_repr(res).unwrap()),
            "0000000000000000000000000000000000000000000000000000000000000003"
        );

        let tmp = mul_by_single_word::<Scalar>(&res, div as u64);
        let tmp = add_single_word::<Scalar>(&tmp, m as u64);
        assert_eq!(Scalar::from_repr(tmp).unwrap(), ten);

        let mut res = Scalar::from_repr(res).unwrap();
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
            let (res, m) = divide_long::<Scalar>(&input.into_repr(), div);

            let tmp = mul_by_single_word::<Scalar>(&res, div as u64);
            let tmp = add_single_word::<Scalar>(&tmp, m as u64);
            assert_eq!(Scalar::from_repr(tmp).unwrap(), input);
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
            let repr = input.into_repr();
            let (res1, m1) = divide_long::<Scalar>(&repr, div);
            let (res2, m2) = divide_long_using_recip::<Scalar>(&repr, divisor, recip, s);
            let (res3, m3) = div_mod_crandall::<Scalar>(&repr, bit as u32);

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
        let ten_repr = ten.into_repr();
        let div = 3;

        let (res, m) = divide_long::<Scalar>(&ten_repr, div);

        assert_eq!(m, 1);
        assert_eq!(
            to_hex(&Scalar::from_repr(res).unwrap()),
            "0000000000000000000000000000000000000000000000000000000000000003"
        );

        let tmp = mul_by_single_word::<Scalar>(&res, div as u64);
        let tmp = add_single_word::<Scalar>(&tmp, m as u64);
        assert_eq!(Scalar::from_repr(tmp).unwrap(), ten);

        let mut res = Scalar::from_repr(res).unwrap();
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
            let (res, m) = divide_long::<Scalar>(&input.into_repr(), div);

            let tmp = mul_by_single_word::<Scalar>(&res, div as u64);
            let tmp = add_single_word::<Scalar>(&tmp, m as u64);
            assert_eq!(Scalar::from_repr(tmp).unwrap(), input);
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
            let repr = input.into_repr();
            let (res1, m1) = divide_long::<Scalar>(&repr, div);
            let (res2, m2) = divide_long_using_recip::<Scalar>(&repr, divisor, recip, s);
            let (res3, m3) = div_mod_crandall::<Scalar>(&repr, bit as u32);

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
        let ten_repr = ten.into_repr();
        let div = 3;

        let (res, m) = divide_long::<Scalar>(&ten_repr, div);

        assert_eq!(m, 1);
        assert_eq!(
            to_hex(&Scalar::from_repr(res).unwrap()),
            "0000000000000000000000000000000000000000000000000000000000000003"
        );

        let tmp = mul_by_single_word::<Scalar>(&res, div as u64);
        let tmp = add_single_word::<Scalar>(&tmp, m as u64);
        assert_eq!(Scalar::from_repr(tmp).unwrap(), ten);

        let mut res = Scalar::from_repr(res).unwrap();
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
            let (res, m) = divide_long::<Scalar>(&input.into_repr(), div);

            let tmp = mul_by_single_word::<Scalar>(&res, div as u64);
            let tmp = add_single_word::<Scalar>(&tmp, m as u64);
            assert_eq!(Scalar::from_repr(tmp).unwrap(), input);
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
            let repr = input.into_repr();
            let (res1, m1) = divide_long::<Scalar>(&repr, div);
            let (res2, m2) = divide_long_using_recip::<Scalar>(&repr, divisor, recip, s);
            let (res3, m3) = div_mod_crandall::<Scalar>(&repr, bit as u32);

            assert_eq!(res1, res2);
            assert_eq!(res1, res3);
            assert_eq!(m1, m2);
            assert_eq!(m1, m3);
        }
    }
}

//-----------------------------------------------------------------------------
// mod_inverse
//-----------------------------------------------------------------------------
pub fn mod_inverse<F: PrimeField>(val: u16, modulus: &F::Repr) -> F::Repr {
    if val == 0 {
        panic!("0 has no inverse!");
    }

    let mut m = val;
    let mut tmp_v = modulus.to_owned();

    let (q, tmp) = divide_long::<F>(&tmp_v, m);
    let mut v = m;
    m = tmp;
    let mut a = q;
    let mut a_neg = true;
    let mut prev_a = F::Repr::from(1);
    let mut prev_a_neg = false;

    while m != 0 {
        let q = v / m;
        let tmp = v % m;
        v = m;
        m = tmp;

        let tmp_a = a;
        let tmp_a_neg = a_neg;

        let (qa, _) = mul_by_single_word_carry::<F>(&a, q as u64);
        if a_neg != prev_a_neg {
            a = prev_a;
            a.add_nocarry(&qa);
            a_neg = prev_a_neg;
        } else if prev_a > qa {
            a = prev_a;
            a.sub_noborrow(&qa);
            a_neg = prev_a_neg;
        } else {
            a = qa;
            a.sub_noborrow(&prev_a);
            a_neg = !a_neg;
        }

        prev_a = tmp_a;
        prev_a_neg = tmp_a_neg;
    }

    if v != 1 {
        panic!("{} has no inverse!", val);
    }

    if prev_a_neg {
        tmp_v.sub_noborrow(&prev_a);
        tmp_v
    } else {
        prev_a
    }
}
