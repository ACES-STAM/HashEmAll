use criterion::{black_box, criterion_group, criterion_main, Criterion};
use ff::PrimeField;
use rand::{thread_rng, Rng};
use zkhash::fields::{bn256::FpBN256, utils};

type Scalar = FpBN256;

fn into_limbs(c: &mut Criterion) {
    let input = utils::random_scalar::<Scalar>(true);

    c.bench_function("BN256 into limbs", move |bench| {
        bench.iter(|| {
            let res = utils::into_limbs(black_box(&input));
            black_box(res);
        });
    });
}

fn from_limbs(c: &mut Criterion) {
    let input = utils::random_scalar::<Scalar>(true);
    let limbs = utils::into_limbs(&input);
    c.bench_function("BN256 from limbs", move |bench| {
        bench.iter(|| {
            let res = utils::from_limbs::<Scalar>(black_box(&limbs));
            black_box(res);
        });
    });
}

fn mult_by_word(c: &mut Criterion) {
    let mut rng = thread_rng();
    let input = utils::random_scalar_rng::<Scalar, _>(true, &mut rng);
    let repr = input.into_repr();
    let mul = rng.gen::<u64>();

    c.bench_function("BN256 multiplication by word", move |bench| {
        bench.iter(|| {
            let res = utils::mul_by_single_word::<Scalar>(black_box(&repr), black_box(mul));
            black_box(res)
        });
    });
}

fn div_by_u16(c: &mut Criterion) {
    let mut rng = thread_rng();
    let input = utils::random_scalar_rng::<Scalar, _>(true, &mut rng);
    let repr = input.into_repr();
    // let div = rng.gen::<u16>();
    let div = 1023;

    c.bench_function("BN256 division by u16", move |bench| {
        bench.iter(|| {
            let (res, m) = utils::divide_long::<Scalar>(black_box(&repr), black_box(div));
            black_box((res, m))
        });
    });
}

fn div_by_u16_recip(c: &mut Criterion) {
    let mut rng = thread_rng();
    let input = utils::random_scalar_rng::<Scalar, _>(true, &mut rng);
    let repr = input.into_repr();
    // let div = rng.gen::<u16>();
    let div = 1023;

    let (divisor, recip) = utils::compute_normalized_divisor_and_reciproical(div);
    let s = (div as u64).leading_zeros();

    c.bench_function(
        "BN256 division by u16 using precomputed reciprocal",
        move |bench| {
            bench.iter(|| {
                let (res, m) = utils::divide_long_using_recip::<Scalar>(
                    black_box(&repr),
                    black_box(divisor),
                    black_box(recip),
                    black_box(s),
                );
                black_box((res, m))
            });
        },
    );
}

fn div_crandall(c: &mut Criterion) {
    let mut rng = thread_rng();
    let input = utils::random_scalar_rng::<Scalar, _>(true, &mut rng);
    let repr = input.into_repr();
    let bit = 10;

    c.bench_function("BN256 division by 2^N-1 using crandall", move |bench| {
        bench.iter(|| {
            let (res, m) = utils::div_mod_crandall::<Scalar>(black_box(&repr), black_box(bit));
            black_box((res, m))
        });
    });
}

fn add_by_word(c: &mut Criterion) {
    let mut rng = thread_rng();
    let input = utils::random_scalar_rng::<Scalar, _>(true, &mut rng);
    let repr = input.into_repr();
    let mul = rng.gen::<u64>();

    c.bench_function("BN256 addition by word", move |bench| {
        bench.iter(|| {
            let res = utils::add_single_word::<Scalar>(black_box(&repr), black_box(mul));
            black_box(res)
        });
    });
}

fn partial_add(c: &mut Criterion) {
    let mut rng = thread_rng();
    let input1 = utils::random_scalar_rng::<Scalar, _>(true, &mut rng);
    let mut repr1 = input1.into_repr();
    let input2 = utils::random_scalar_rng::<Scalar, _>(true, &mut rng);
    let repr2 = input2.into_repr();

    c.bench_function("BN256 partial addition", move |bench| {
        bench.iter(|| {
            utils::partial_add_inplace::<Scalar>(black_box(&mut repr1), black_box(&repr2));
            black_box(repr1)
        });
    });
}

fn full_shr(c: &mut Criterion) {
    let mut rng = thread_rng();
    let input = utils::random_scalar_rng::<Scalar, _>(true, &mut rng);
    let repr = input.into_repr();
    let shift = rng.gen::<u32>() % 64;

    c.bench_function("BN256 full shift right", move |bench| {
        bench.iter(|| {
            let res = utils::full_shr::<Scalar>(black_box(&repr), black_box(shift));
            black_box(res)
        });
    });
}

fn full_shl(c: &mut Criterion) {
    let mut rng = thread_rng();
    let input = utils::random_scalar_rng::<Scalar, _>(true, &mut rng);
    let repr = input.into_repr();
    let shift = rng.gen::<u32>() % 64;

    c.bench_function("BN256 full shift left", move |bench| {
        bench.iter(|| {
            let res = utils::full_shl::<Scalar>(black_box(&repr), black_box(shift));
            black_box(res)
        });
    });
}
fn partial_shl(c: &mut Criterion) {
    let mut rng = thread_rng();
    let input = utils::random_scalar_rng::<Scalar, _>(true, &mut rng);
    let repr = input.into_repr();
    let shift = rng.gen::<u32>() % 64;

    c.bench_function("BN256 partial shift left", move |bench| {
        bench.iter(|| {
            let res = utils::partial_shl::<Scalar>(black_box(&repr), black_box(shift));
            black_box(res)
        });
    });
}

fn criterion_benchmark_fields_bn256(c: &mut Criterion) {
    mult_by_word(c);
    div_by_u16(c);
    div_by_u16_recip(c);
    div_crandall(c);
    add_by_word(c);
    partial_add(c);
    full_shr(c);
    full_shl(c);
    partial_shl(c);
    into_limbs(c);
    from_limbs(c);
}

criterion_group!(
    name = benches;
    config = Criterion::default();
    targets = criterion_benchmark_fields_bn256
);
criterion_main!(benches);
