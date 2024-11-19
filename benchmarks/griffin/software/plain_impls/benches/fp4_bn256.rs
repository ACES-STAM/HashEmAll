use criterion::{black_box, criterion_group, criterion_main, Criterion};
use rand::{thread_rng, Rng};
use zkhash::fields::{bn256::FpBN256, utils4};

type Scalar = FpBN256;

fn into_limbs(c: &mut Criterion) {
    let input = utils4::random_scalar::<Scalar>(true);

    c.bench_function("BN256_4 into limbs", move |bench| {
        bench.iter(|| {
            let res = utils4::into_limbs(black_box(&input));
            black_box(res);
        });
    });
}

fn from_limbs(c: &mut Criterion) {
    let input = utils4::random_scalar::<Scalar>(true);
    let limbs = utils4::into_limbs(&input);
    c.bench_function("BN256_4 from limbs", move |bench| {
        bench.iter(|| {
            let res = utils4::from_limbs::<Scalar>(black_box(&limbs));
            black_box(res);
        });
    });
}

fn mult_by_word(c: &mut Criterion) {
    let mut rng = thread_rng();
    let input = utils4::random_scalar_rng::<Scalar, _>(true, &mut rng);
    let repr = utils4::into_limbs(&input);
    let mul = rng.gen::<u64>();

    c.bench_function("BN256_4 multiplication by word", move |bench| {
        bench.iter(|| {
            let res = utils4::mul_by_single_word(black_box(&repr), black_box(mul));
            black_box(res)
        });
    });
}

fn div_by_u16(c: &mut Criterion) {
    let mut rng = thread_rng();
    let input = utils4::random_scalar_rng::<Scalar, _>(true, &mut rng);
    let repr = utils4::into_limbs(&input);
    // let div = rng.gen::<u16>();
    let div = 1023;

    c.bench_function("BN256_4 division by u16", move |bench| {
        bench.iter(|| {
            let (res, m) = utils4::divide_long(black_box(&repr), black_box(div));
            black_box((res, m))
        });
    });
}

fn div_by_u16_recip(c: &mut Criterion) {
    let mut rng = thread_rng();
    let input = utils4::random_scalar_rng::<Scalar, _>(true, &mut rng);
    let repr = utils4::into_limbs(&input);
    // let div = rng.gen::<u16>();
    let div = 1023;

    let (divisor, recip) = utils4::compute_normalized_divisor_and_reciproical(div);
    let s = (div as u64).leading_zeros();

    c.bench_function(
        "BN256_4 division by u16 using precomputed reciprocal",
        move |bench| {
            bench.iter(|| {
                let (res, m) = utils4::divide_long_using_recip(
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
    let input = utils4::random_scalar_rng::<Scalar, _>(true, &mut rng);
    let repr = utils4::into_limbs(&input);
    let bit = 10;

    c.bench_function("BN256_4 division by 2^N-1 using crandall", move |bench| {
        bench.iter(|| {
            let (res, m) = utils4::div_mod_crandall(black_box(&repr), black_box(bit));
            black_box((res, m))
        });
    });
}

fn div_mg(c: &mut Criterion) {
    let mut rng = thread_rng();
    let input = utils4::random_scalar_rng::<Scalar, _>(true, &mut rng);
    let repr = utils4::into_limbs(&input);

    c.bench_function("BN256_4 division by 1023 using MG", move |bench| {
        bench.iter(|| {
            let (res, m) = utils4::div1023(black_box(&repr));
            black_box((res, m))
        });
    });
}

fn add_by_word(c: &mut Criterion) {
    let mut rng = thread_rng();
    let input = utils4::random_scalar_rng::<Scalar, _>(true, &mut rng);
    let repr = utils4::into_limbs(&input);
    let mul = rng.gen::<u64>();

    c.bench_function("BN256_4 addition by word", move |bench| {
        bench.iter(|| {
            let res = utils4::add_single_word(black_box(&repr), black_box(mul));
            black_box(res)
        });
    });
}

fn partial_add(c: &mut Criterion) {
    let mut rng = thread_rng();
    let input1 = utils4::random_scalar_rng::<Scalar, _>(true, &mut rng);
    let repr1 = utils4::into_limbs(&input1);
    let input2 = utils4::random_scalar_rng::<Scalar, _>(true, &mut rng);
    let repr2 = utils4::into_limbs(&input2);

    c.bench_function("BN256_4 partial addition", move |bench| {
        bench.iter(|| {
            let res = utils4::partial_add(black_box(&repr1), black_box(&repr2));
            black_box(res)
        });
    });
}

fn full_shr(c: &mut Criterion) {
    let mut rng = thread_rng();
    let input = utils4::random_scalar_rng::<Scalar, _>(true, &mut rng);
    let repr = utils4::into_limbs(&input);
    let shift = rng.gen::<u32>() % 64;

    c.bench_function("BN256_4 full shift right", move |bench| {
        bench.iter(|| {
            let res = utils4::full_shr(black_box(&repr), black_box(shift));
            black_box(res)
        });
    });
}

fn full_shl(c: &mut Criterion) {
    let mut rng = thread_rng();
    let input = utils4::random_scalar_rng::<Scalar, _>(true, &mut rng);
    let repr = utils4::into_limbs(&input);
    let shift = rng.gen::<u32>() % 64;

    c.bench_function("BN256_4 full shift left", move |bench| {
        bench.iter(|| {
            let res = utils4::full_shl(black_box(&repr), black_box(shift));
            black_box(res)
        });
    });
}
fn partial_shl(c: &mut Criterion) {
    let mut rng = thread_rng();
    let input = utils4::random_scalar_rng::<Scalar, _>(true, &mut rng);
    let repr = utils4::into_limbs(&input);
    let shift = rng.gen::<u32>() % 64;

    c.bench_function("BN256_4 partial shift left", move |bench| {
        bench.iter(|| {
            let res = utils4::partial_shl(black_box(&repr), black_box(shift));
            black_box(res)
        });
    });
}

fn criterion_benchmark_fields_st(c: &mut Criterion) {
    mult_by_word(c);
    div_by_u16(c);
    div_by_u16_recip(c);
    div_crandall(c);
    div_mg(c);
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
    targets = criterion_benchmark_fields_st
);
criterion_main!(benches);
