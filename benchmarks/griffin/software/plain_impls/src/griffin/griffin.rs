use crate::merkle_tree::merkle_tree_fp::MerkleTreeHash;
use super::griffin_params::GriffinParams;
use ff::{PrimeField, SqrtField};
use std::sync::Arc;

#[derive(Clone, Debug)]
pub struct Griffin<S: PrimeField + SqrtField> {
    pub(crate) params: Arc<GriffinParams<S>>,

}

impl<S: PrimeField + SqrtField> Griffin<S> {
    pub fn new(params: &Arc<GriffinParams<S>>) -> Self {
        Griffin {
            params: Arc::clone(params),
        }
    }
    pub fn print_params(&self) {
        self.params.print_parameters(); // Calls the GriffinParams print_parameters function
    }

    pub fn get_t(&self) -> usize {
        self.params.t
    }

    fn affine_3(&self, input: &mut [S], round: usize) {
        let mut sum = input[0];
        input.iter().skip(1).for_each(|el| sum.add_assign(el));

        if round < self.params.rounds - 1 {
            for (el, rc) in input.iter_mut().zip(self.params.round_constants[round].iter()) {
                el.add_assign(&sum);
                el.add_assign(rc); // add round constant
            }
        } else {
            for el in input.iter_mut() {
                el.add_assign(&sum);
            }
        }
    }

    fn affine_4(&self, input: &mut [S], round: usize) {
        let mut t_0 = input[0];
        t_0.add_assign(&input[1]);
        let mut t_1 = input[2];
        t_1.add_assign(&input[3]);
        let mut t_2 = input[1];
        t_2.double();
        t_2.add_assign(&t_1);
        let mut t_3 = input[3];
        t_3.double();
        t_3.add_assign(&t_0);
        let mut t_4 = t_1;
        t_4.double();
        t_4.double();
        t_4.add_assign(&t_3);
        let mut t_5 = t_0;
        t_5.double();
        t_5.double();
        t_5.add_assign(&t_2);
        let mut t_6 = t_3;
        t_6.add_assign(&t_5);
        let mut t_7 = t_2;
        t_7.add_assign(&t_4);
        input[0] = t_6;
        input[1] = t_5;
        input[2] = t_7;
        input[3] = t_4;

        if round < self.params.rounds - 1 {
            for (i, rc) in input.iter_mut().zip(self.params.round_constants[round].iter()) {
                i.add_assign(rc);
            }
        }
    }

    fn affine(&self, input: &mut [S], round: usize) {
        if self.params.t == 3 {
            self.affine_3(input, round);
            return;
        }
        if self.params.t == 4 {
            self.affine_4(input, round);
            return;
        }

        let t4 = self.params.t / 4;

        for el in input.chunks_exact_mut(4) {
            let mut t_0 = el[0];
            t_0.add_assign(&el[1]);
            let mut t_1 = el[2];
            t_1.add_assign(&el[3]);
            let mut t_2 = el[1];
            t_2.double();
            t_2.add_assign(&t_1);
            let mut t_3 = el[3];
            t_3.double();
            t_3.add_assign(&t_0);
            let mut t_4 = t_1;
            t_4.double();
            t_4.double();
            t_4.add_assign(&t_3);
            let mut t_5 = t_0;
            t_5.double();
            t_5.double();
            t_5.add_assign(&t_2);
            let mut t_6 = t_3;
            t_6.add_assign(&t_5);
            let mut t_7 = t_2;
            t_7.add_assign(&t_4);
            el[0] = t_6;
            el[1] = t_5;
            el[2] = t_7;
            el[3] = t_4;
        }

        let mut stored = [S::zero(); 4];
        for l in 0..4 {
            stored[l] = input[l];
            for j in 1..t4 {
                stored[l].add_assign(&input[4 * j + l]);
            }
        }

        for i in 0..input.len() {
            input[i].add_assign(&stored[i % 4]);
            if round < self.params.rounds - 1 {
                input[i].add_assign(&self.params.round_constants[round][i]);
            }
        }
    }

    fn l(y01_i: &mut S, y0: &S, x: &S, i: usize) -> S {
        if i == 0 {
            y01_i.to_owned()
        } else {
            y01_i.add_assign(y0);
            let mut out = y01_i.to_owned();
            out.add_assign(x);
            out
        }
    }

    fn non_linear(&self, input: &[S]) -> Vec<S> {
        println!("Non-linear function input: {:?}", input); // Print the input
    
        let mut output = input.to_owned();
        output[0] = output[0].pow(self.params.d_inv);
    
        output[1].square();
        match self.params.d {
            3 => {}
            5 => output[1].square(),
            7 => {
                let tmp = output[1];
                output[1].square();
                output[1].mul_assign(&tmp);
            }
            _ => panic!(),
        }
        output[1].mul_assign(&input[1]);
    
        let mut y01_i = output[0].to_owned();
        let y0 = y01_i.to_owned();
        y01_i.add_assign(&output[1]);
    
        for (i, ((out, inp), con)) in output.iter_mut().skip(2).zip(input.iter().skip(1)).zip(self.params.alpha_beta.iter()).enumerate() {
            let mut l = Self::l(&mut y01_i, &y0, inp, i);
            let mut l_squ = l.to_owned();
            l_squ.square();
            l.mul_assign(&con[0]);
            l.add_assign(&l_squ);
            l.add_assign(&con[1]);
            out.mul_assign(&l);
        }
    
        println!("Non-linear function output: {:?}", output); // Print the output
    
        output
    }
    

    pub fn permutation(&self, input: &[S]) -> Vec<S> {
        let mut current_state = input.to_owned();
    
        // Initial state before starting rounds
        println!("Initial State: {:?}", current_state);
    
        // First affine transformation (without round constants in the last round)
        self.affine(&mut current_state, self.params.rounds);
        println!("After Initial Affine (before rounds): {:?}", current_state);
    
        for r in 0..self.params.rounds {
            println!("\n--- Round {} ---", r + 1);
            println!("Input to Round {}: {:?}", r + 1, current_state);
    
            // Non-linear layer
            current_state = self.non_linear(&current_state);
            println!("After Non-Linear Layer in Round {}: {:?}", r + 1, current_state);
    
            // Affine layer
            self.affine(&mut current_state, r);
            println!("After Affine Layer in Round {}: {:?}", r + 1, current_state);
        }
    
        // Final state after all rounds
        println!("Final State after 14 rounds: {:?}", current_state);
        
        current_state
    }
    
}

impl<S: PrimeField + SqrtField> MerkleTreeHash<S> for Griffin<S> {
    fn compress(&self, input: &[&S; 2]) -> S {
        self.permutation(&[input[0].to_owned(), input[1].to_owned(), S::zero()])[0]
    }
}


#[cfg(test)]
mod griffin_tests_bn254 {

    use generic_array::typenum::U256;

    use super::*;
    use crate::{
        fields::{bn254::FpBN254, utils}, // Import BN254 field and utils
        griffin::griffin_params::GriffinParams, // Import GriffinParams
    };
    use std::sync::Arc;

    type Scalar = FpBN254;
    static D: usize = 5; // Non-linear degree, d = 5


    #[test]
    fn test_bn254_griffin_permutation_state_3() {
        let params = Arc::new(GriffinParams::<Scalar>::new(3, D, 14));
        let griffin = Griffin::new(&params);
        griffin.print_params();

        let t = griffin.params.t;
        let input: Vec<Scalar> = (0..t).map(|_| utils::random_scalar(true)).collect();

        let permuted_output = griffin.permutation(&input);

        println!("State size 3: Input: {:?}", input);
        println!("State size 3: Permuted Output: {:?}", permuted_output);
    }

    #[test]
    fn test_bn254_griffin_permutation_state_4() {
        let params = Arc::new(GriffinParams::<Scalar>::new(4, D, 11));
        let griffin = Griffin::new(&params);
        griffin.print_params();

        let t = griffin.params.t;
        let input: Vec<Scalar> = (0..t).map(|_| utils::random_scalar(true)).collect();

        let permuted_output = griffin.permutation(&input);

        println!("State size 4: Input: {:?}", input);
        println!("State size 4: Permuted Output: {:?}", permuted_output);
    }

    #[test]
    fn test_bn254_griffin_permutation_state_8() {
        let params = Arc::new(GriffinParams::<Scalar>::new(8, D, 9));
        let griffin = Griffin::new(&params);
        griffin.print_params();

        let t = griffin.params.t;
        let input: Vec<Scalar> = (0..t).map(|_| utils::random_scalar(true)).collect();

        let permuted_output = griffin.permutation(&input);

        println!("State size 8: Input: {:?}", input);
        println!("State size 8: Permuted Output: {:?}", permuted_output);
    }
    #[test]
  
    fn test_bn254_griffin_permutation_state_12() {
        let params = Arc::new(GriffinParams::<Scalar>::new(12, D, 9));
        let griffin = Griffin::new(&params);
        griffin.print_params();

        let t = griffin.params.t;
        let input: Vec<Scalar> = (0..t).map(|_| utils::random_scalar(true)).collect();

        let permuted_output = griffin.permutation(&input);

        println!("State size 12: Input: {:?}", input);
        println!("State size 12: Permuted Output: {:?}", permuted_output);
    }

    #[test]
    fn test_bn254_griffin_permutation_state_16() {
        let params = Arc::new(GriffinParams::<Scalar>::new(16, D, 9));
        let griffin = Griffin::new(&params);
        griffin.print_params();

        let t = griffin.params.t;
        let input: Vec<Scalar> = (0..t).map(|_| utils::random_scalar(true)).collect();

        let permuted_output = griffin.permutation(&input);

        println!("State size 16: Input: {:?}", input);
        println!("State size 16: Permuted Output: {:?}", permuted_output);
    }

    #[test]
    fn test_bn254_griffin_permutation_state_20() {
        let params = Arc::new(GriffinParams::<Scalar>::new(20, D, 9));
        let griffin = Griffin::new(&params);
        griffin.print_params();

        let t = griffin.params.t;
        let input: Vec<Scalar> = (0..t).map(|_| utils::random_scalar(true)).collect();

        let permuted_output = griffin.permutation(&input);

        println!("State size 20: Input: {:?}", input);
        println!("State size 20: Permuted Output: {:?}", permuted_output);
    }

    #[test]
    fn test_bn254_griffin_permutation_state_24() {
        let params = Arc::new(GriffinParams::<Scalar>::new(24, D, 9));
        let griffin = Griffin::new(&params);
        griffin.print_params();

        let t = griffin.params.t;
        let input: Vec<Scalar> = (0..t).map(|_| utils::random_scalar(true)).collect();

        let permuted_output = griffin.permutation(&input);

        println!("State size 24: Input: {:?}", input);
        println!("State size 24: Permuted Output: {:?}", permuted_output);
    }
   
}
