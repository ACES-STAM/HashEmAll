use crate::field::{Field, FieldElement};
use num_bigint::BigUint;
use std::str::FromStr;
use num_traits::ToPrimitive;
use num_traits::One;

pub struct ReinforcedConcrete {
    pub p_value: BigUint,
    pub field: Field,
    pub alphas: [FieldElement; 2],
    pub betas: [FieldElement; 2],
    pub round_constants: Vec<[FieldElement; 3]>,
    pub s_values: Vec<BigUint>,
    pub sbox_threshold: FieldElement,
    pub sbox_u256: Vec<FieldElement>,
    pub pre_rounds: i32,
    pub total_rounds: u32
}

impl ReinforcedConcrete {
    pub fn new() -> Self {
        let p_value_str = "21888242871839275222246405745257275088548364400416034343698204186575808495617";
        let p_value = BigUint::from_str(p_value_str).expect("Failed to parse the number");
        let field = Field::new(p_value.clone());

        let alphas_values = [1u32, 3u32];
        let alphas: [FieldElement; 2] = [
            FieldElement::new(BigUint::from(alphas_values[0]), field.clone()),
            FieldElement::new(BigUint::from(alphas_values[1]), field.clone()),
        ];

        let betas_values = [2u32, 4u32];
        let betas: [FieldElement; 2] = [
            FieldElement::new(BigUint::from(betas_values[0]), field.clone()),
            FieldElement::new(BigUint::from(betas_values[1]), field.clone()),
        ];

        let round_constants = vec![
            [
                FieldElement::new(BigUint::from(5748013u32), field.clone()), 
                FieldElement::new(BigUint::from(8959805u32), field.clone()), 
                FieldElement::new(BigUint::from(5322109u32), field.clone()),
            ],
            [
                FieldElement::new(BigUint::from(9833447u32), field.clone()), 
                FieldElement::new(BigUint::from(8565022u32), field.clone()), 
                FieldElement::new(BigUint::from(7968812u32), field.clone()),
            ],
            [
                FieldElement::new(BigUint::from(15008204u32), field.clone()), 
                FieldElement::new(BigUint::from(15007603u32), field.clone()), 
                FieldElement::new(BigUint::from(9832189u32), field.clone()),
            ],
            [
                FieldElement::new(BigUint::from(2114001u32), field.clone()), 
                FieldElement::new(BigUint::from(5269258u32), field.clone()), 
                FieldElement::new(BigUint::from(11741327u32), field.clone()),
            ],
            [
                FieldElement::new(BigUint::from(1743068u32), field.clone()), 
                FieldElement::new(BigUint::from(2860587u32), field.clone()), 
                FieldElement::new(BigUint::from(10360691u32), field.clone()),
            ],
            [
                FieldElement::new(BigUint::from(3644088u32), field.clone()), 
                FieldElement::new(BigUint::from(5132511u32), field.clone()), 
                FieldElement::new(BigUint::from(15861760u32), field.clone()),
            ],
            [
                FieldElement::new(BigUint::from(11168023u32), field.clone()), 
                FieldElement::new(BigUint::from(2253203u32), field.clone()), 
                FieldElement::new(BigUint::from(14099134u32), field.clone()),
            ],
            [
                FieldElement::new(BigUint::from(1160717u32), field.clone()), 
                FieldElement::new(BigUint::from(14097647u32), field.clone()), 
                FieldElement::new(BigUint::from(6717918u32), field.clone()),
            ],
        ];

        let s_values = vec![
            BigUint::from_str("12345678901234567890").unwrap(),
            BigUint::from_str("98765432109876543210").unwrap(),
            BigUint::from_str("11223344556677889900").unwrap(),
            BigUint::from_str("99887766554433221100").unwrap(),
            BigUint::from_str("31415926535897932384").unwrap(),
        ];
        let pre_rounds = 3;
        let total_rounds = 7;

        let sbox_threshold = FieldElement::new(BigUint::from(10u32), field.clone());
        let sbox_u256: Vec<FieldElement> = self::instantiate_sbox(&field, 256);
        ReinforcedConcrete { 
            p_value,
            field,
            alphas,
            betas, 
            round_constants,
            s_values,
            sbox_threshold,
            sbox_u256,
            pre_rounds,
            total_rounds
        }
    }

    pub fn bricks(&self, state: &[FieldElement; 3]) -> [FieldElement; 3] {
        println!("Bricks - Input State: {:?}", state.iter().map(|x| x.to_biguint()).collect::<Vec<_>>());
        let mut new_state: [FieldElement; 3] = [
            self.field.zero(),
            self.field.zero(),
            self.field.zero(),
        ];
        
        let pow_two = BigUint::from_str("2").unwrap();
        let mut x1_sq = state[0].clone().pow(pow_two.clone());
        let mut x2_sq = state[1].clone().pow(pow_two.clone());

        // 1st term = x1^5
        let pow_five = BigUint::from_str("5").unwrap();
        let mut term_one = state[0].clone().pow(pow_five.clone());
        new_state[0] = term_one;

        // 2nd term = x2(x1^2 + a1*x1 + b)
        let mut term_two = x1_sq.clone();
        let temp = state[0].clone().multiply(&self.alphas[0]);
        term_two = term_two.add(&temp);
        term_two = term_two.add(&self.betas[0]);
        term_two = term_two.multiply(&state[1]);
        new_state[1] = term_two;

        // 3rd term = x3(x2^2 + a2*x2 + b2)
        let mut term_three = x2_sq.clone();
        let temp_three = state[1].clone().multiply(&self.alphas[1]);
        term_three = term_three.add(&temp_three);
        term_three = term_three.add(&self.betas[1]);
        term_three = term_three.multiply(&state[2]);
        new_state[2] = term_three;

        println!("Bricks - Output State: {:?}", new_state.iter().map(|x| x.to_biguint()).collect::<Vec<_>>());
        new_state
    }

    pub fn concrete(&self, state: &[FieldElement; 3], round_index: usize) -> [FieldElement; 3] {
        println!("Concrete - Input State: {:?}, Round Index: {}", state.iter().map(|x| x.to_biguint()).collect::<Vec<_>>(), round_index);
        let mds_matrix = [
            [BigUint::from(2u32), BigUint::from(1u32), BigUint::from(1u32)],
            [BigUint::from(1u32), BigUint::from(2u32), BigUint::from(1u32)],
            [BigUint::from(1u32), BigUint::from(1u32), BigUint::from(2u32)],
        ];

        let mut new_state: [FieldElement; 3] = [
            self.field.zero(),
            self.field.zero(),
            self.field.zero(),
        ];

        // Perform MDS matrix multiplication
        for i in 0..3 {
            for j in 0..3 {
                let mds_value = FieldElement::new(mds_matrix[i][j].clone(), self.field.clone());
                new_state[i] = new_state[i].add(&state[j].clone().multiply(&mds_value));
            }
        }

        // Add the round constant for the given round index
        let round_constant = &self.round_constants[round_index];
        for i in 0..3 {
            new_state[i] = new_state[i].add(&round_constant[i]);
        }
        println!("Concrete - Output State: {:?}", new_state.iter().map(|x| x.to_biguint()).collect::<Vec<_>>());
        new_state
    }

    pub fn decomp(&self, x: &FieldElement) -> Vec<FieldElement> {
        println!("Decomp - Input: {:?}", x.to_biguint());
        let mut digits = vec![];
        let mut remainder = x.to_biguint(); // Convert FieldElement to BigUint for calculation

        for s_i in self.s_values.iter().rev() {
            let digit = remainder.clone() % s_i;
            remainder /= s_i;
            digits.push(FieldElement::new(digit, self.field.clone()));
        }

        digits.reverse();
        println!("Decomp - Output Digits: {:?}", digits.iter().map(|d| d.to_biguint()).collect::<Vec<_>>());
        digits
    }

    pub fn comp(&self, digits: Vec<FieldElement>) -> FieldElement {
        println!("Comp - Input Digits: {:?}", digits.iter().map(|d| d.to_biguint()).collect::<Vec<_>>());
        let mut result = self.field.zero();
        let mut product = FieldElement::new(BigUint::one(), self.field.clone());
    
        for (i, digit) in digits.iter().enumerate() {
            // Calculate the term and add to result
            let term = digit.multiply(&product);
            result = result.add(&term);
    
            // Update the product if there are more values to multiply
            if i < self.s_values.len() - 1 {
                let next_s_value = FieldElement::new(self.s_values[i + 1].clone(), self.field.clone());
                product = product.multiply(&next_s_value);
            }
        }
    
        println!("Comp - Final Output: {:?}", result.to_biguint());
        result
    }
    

    pub fn sbox(&self, x: &FieldElement) -> FieldElement {
        println!("SBox - Input: {:?}", x.to_biguint());
        let x_biguint = x.to_biguint();
        let vu_256_biguint = self.sbox_threshold.to_biguint();

        if x_biguint < vu_256_biguint {
            let index = x_biguint.to_u32().expect("x must fit into u32 for indexing") as usize;
            let substitution = &self.sbox_u256[index];
            println!("SBox - Output Substitution: {:?}", substitution.to_biguint());
            substitution.clone()
        } else {
            println!("SBox - Output (No Substitution): {:?}", x.to_biguint());
            x.clone()
        }
    }

    pub fn bar(&self, x: &FieldElement) -> FieldElement {
        println!("Bar - Input: {:?}", x.to_biguint());
        let digits = self.decomp(x);
        let transformed_digits: Vec<FieldElement> = digits
            .into_iter()
            .map(|digit| self.sbox(&digit))
            .collect();
        let result = self.comp(transformed_digits);
        println!("Bar - Output: {:?}", result.to_biguint());
        result
    }

    pub fn bars(&self, state: &[FieldElement; 3]) -> [FieldElement; 3] {
        println!("Bars - Input State: {:?}", state.iter().map(|x| x.to_biguint()).collect::<Vec<_>>());
        let mut new_state: [FieldElement; 3] = [
            self.field.zero(),
            self.field.zero(),
            self.field.zero(),
        ];
        for i in 0..3 {
            new_state[i] = self.bar(&state[i]);
        }
        println!("Bars - Output State: {:?}", new_state.iter().map(|x| x.to_biguint()).collect::<Vec<_>>());
        new_state
    }

    pub fn permutation(&self, input: &[FieldElement; 3]) -> [FieldElement; 3] {
        println!("Permutation - Input: {:?}", input.iter().map(|x| x.to_biguint()).collect::<Vec<_>>());
        let mut current_state = input.clone();
        current_state = self.concrete(&current_state, 0);

        for i in 1..=self.pre_rounds as usize {
            current_state = self.bricks(&current_state);
            current_state = self.concrete(&current_state, i);
        }

        current_state = self.bars(&current_state);
        current_state = self.concrete(&current_state, (self.pre_rounds + 1) as usize);

        for i in (self.pre_rounds + 2) as usize..=self.total_rounds as usize {
            current_state = self.bricks(&current_state);
            current_state = self.concrete(&current_state, i);
        }

        println!("Permutation - Output: {:?}", current_state.iter().map(|x| x.to_biguint()).collect::<Vec<_>>());
        current_state
    }

    pub fn hash_function(&self, el1: &FieldElement, el2: &FieldElement) -> FieldElement {
        println!("Hash Function - Inputs: {:?}, {:?}", el1.to_biguint(), el2.to_biguint());
        let mut input: [FieldElement; 3] = [el1.clone(), el2.clone(), self.field.zero()];
        input = self.permutation(&input);
        println!("Hash Function - Output: {:?}", input[0].to_biguint());
        input[0].clone()
    }
}

pub fn instantiate_sbox(field: &Field, v: usize) -> Vec<FieldElement> {
    let mut sbox = Vec::with_capacity(v);
    sbox.push(field.zero());

    (1..v).for_each(|i| {
        let i_biguint = BigUint::from(i as u32);
        sbox.push(FieldElement::new(i_biguint, field.clone()));
    });
    sbox
}