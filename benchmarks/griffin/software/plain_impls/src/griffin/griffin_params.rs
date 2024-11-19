use ff::{LegendreSymbol, PrimeField, SqrtField};
use sha3::{
    digest::{core_api::XofReaderCoreWrapper, ExtendableOutput, Update, XofReader},
    Shake128, Shake128ReaderCore,
};

use crate::fields::utils;

#[derive(Clone, Debug)]
pub struct GriffinParams<F: PrimeField + SqrtField> {
    pub(crate) round_constants: Vec<Vec<F>>,
    pub(crate) t: usize,
    pub(crate) d: usize,
    pub(crate) d_inv: F::Repr,
    pub(crate) rounds: usize,
    pub(crate) alpha_beta: Vec<[F; 2]>,
    #[allow(dead_code)]
    pub(crate) mat: Vec<Vec<F>>,
}

impl<F: PrimeField + SqrtField> GriffinParams<F> {
    pub const INIT_SHAKE: &'static str = "Griffin";

    pub fn new(t: usize, d: usize, rounds: usize) -> Self {
        assert!(t == 3 || t % 4 == 0);
        assert!(d == 3 || d == 5 || d == 7);
        assert!(rounds >= 1);

        let mut shake = Self::init_shake();

        let d_inv = Self::calculate_d_inv(d as u64);
        let round_constants = Self::instantiate_rc(t, rounds, &mut shake);
        let alpha_beta = Self::instantiate_alpha_beta(t, &mut shake);

        let mat = Self::instantiate_matrix(t);

        GriffinParams {
            round_constants,
            t,
            d,
            d_inv,
            rounds,
            alpha_beta,
            mat,
        }
    }

    fn calculate_d_inv(d: u64) -> F::Repr {
        let mut p_1 = F::one();
        p_1.negate();
        let p_1 = p_1.into_repr();
        utils::mod_inverse::<F>(d as u16, &p_1)
    }

    fn init_shake() -> XofReaderCoreWrapper<Shake128ReaderCore> {
        let mut shake = Shake128::default();
        shake.update(Self::INIT_SHAKE.as_bytes());
        for i in F::char().as_ref() {
            shake.update(&u64::to_le_bytes(*i));
        }
        shake.finalize_xof()
    }

    fn instantiate_rc(t: usize, rounds: usize, shake: &mut dyn XofReader) -> Vec<Vec<F>> {
        (0..rounds - 1)
            .map(|_| {
                (0..t)
                    .map(|_| utils::field_element_from_shake(shake))
                    .collect()
            })
            .collect()
    }

    fn instantiate_alpha_beta(t: usize, shake: &mut dyn XofReader) -> Vec<[F; 2]> {
        let mut alpha_beta = Vec::with_capacity(t - 2);

        // random alpha/beta
        loop {
            let alpha = utils::field_element_from_shake_without_0::<F>(shake);
            let mut beta = utils::field_element_from_shake_without_0::<F>(shake);
            // distinct
            while alpha == beta {
                beta = utils::field_element_from_shake_without_0::<F>(shake);
            }
            let mut symbol = alpha;
            symbol.square();
            let mut tmp = beta;
            tmp.double();
            tmp.double();
            symbol.sub_assign(&tmp);
            if symbol.legendre() == LegendreSymbol::QuadraticNonResidue {
                alpha_beta.push([alpha, beta]);
                break;
            }
        }

        // other alphas/betas
        for i in 2..t - 1 {
            let sq = i * i;
            let mut alpha = alpha_beta[0][0];
            let mut beta = alpha_beta[0][1];
            let i_ = utils::from_u64::<F>(i as u64);
            let sq_ = utils::from_u64::<F>(sq as u64);
            alpha.mul_assign(&i_);
            beta.mul_assign(&sq_);
            // distinct
            while alpha == beta {
                beta = utils::field_element_from_shake_without_0::<F>(shake);
            }

            #[cfg(debug_assertions)]
            {
                // check if really ok
                let mut symbol = alpha;
                symbol.square();
                let mut tmp = beta;
                tmp.double();
                tmp.double();
                symbol.sub_assign(&tmp);
                assert_eq!(symbol.legendre(), LegendreSymbol::QuadraticNonResidue);
            }

            alpha_beta.push([alpha, beta]);
        }

        alpha_beta
    }

    fn circ_mat(row: &[F]) -> Vec<Vec<F>> {
        let t = row.len();
        let mut mat: Vec<Vec<F>> = Vec::with_capacity(t);
        let mut rot = row.to_owned();
        mat.push(rot.clone());
        for _ in 1..t {
            rot.rotate_right(1);
            mat.push(rot.clone());
        }
        mat
    }

    fn instantiate_matrix(t: usize) -> Vec<Vec<F>> {
        if t == 3 {
            let row = vec![utils::from_u64(2), utils::from_u64(1), utils::from_u64(1)];
            Self::circ_mat(&row)
        } else {
            let row1 = vec![
                utils::from_u64(5),
                utils::from_u64(7),
                utils::from_u64(1),
                utils::from_u64(3),
            ];
            let row2 = vec![
                utils::from_u64(4),
                utils::from_u64(6),
                utils::from_u64(1),
                utils::from_u64(1),
            ];
            let row3 = vec![
                utils::from_u64(1),
                utils::from_u64(3),
                utils::from_u64(5),
                utils::from_u64(7),
            ];
            let row4 = vec![
                utils::from_u64(1),
                utils::from_u64(1),
                utils::from_u64(4),
                utils::from_u64(6),
            ];
            let c_mat = vec![row1, row2, row3, row4];
            if t == 4 {
                c_mat
            } else {
                assert_eq!(t % 4, 0);
                let mut mat: Vec<Vec<F>> = vec![vec![F::zero(); t]; t];
                for (row, matrow) in mat.iter_mut().enumerate().take(t) {
                    for (col, matitem) in matrow.iter_mut().enumerate().take(t) {
                        let row_mod = row % 4;
                        let col_mod = col % 4;
                        *matitem = c_mat[row_mod][col_mod];
                        if row / 4 == col / 4 {
                            matitem.add_assign(&c_mat[row_mod][col_mod]);
                        }
                    }
                }
                mat
            }
        }
    }

    pub fn print_parameters(&self) {
        // Print round constants
        println!("Round Constants:");
        for (round_idx, round) in self.round_constants.iter().enumerate() {
            println!("Round {}: ", round_idx);
            for (i, constant) in round.iter().enumerate() {
                println!("  Constant {}: {}", i, constant);
            }
        }

        // Print alpha and beta
        println!("\nAlpha-Beta Pairs:");
        for (i, alpha_beta) in self.alpha_beta.iter().enumerate() {
            println!(
                "  Pair {}: Alpha = {}, Beta = {}",
                i, alpha_beta[0], alpha_beta[1]
            );
        }

        // Print matrix
        println!("\nMatrix (Affine Layer):");
        for (i, row) in self.mat.iter().enumerate() {
            let row_str: Vec<String> = row.iter().map(|v| v.to_string()).collect();
            println!("Row {}: {}", i, row_str.join(", "));
        }

        // Print other parameters
        println!("\nt: {}, d: {}, d_inv: {:?}", self.t, self.d, self.d_inv);
        println!("Number of rounds: {}", self.rounds);
    }

    pub fn get_t(&self) -> usize {
        self.t
    }

    pub fn get_rounds(&self) -> usize {
        self.rounds
    }
}
