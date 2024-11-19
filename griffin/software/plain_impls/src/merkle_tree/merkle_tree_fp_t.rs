use ff::PrimeField;
use std::marker::PhantomData;

pub trait MerkleTreeHash<F: PrimeField, const T: usize> {
    fn compress(&self, input1: &[F; T], input2: &[F; T]) -> [F; T];
}

#[derive(Clone, Debug)]
pub struct MerkleTree<F: PrimeField, const T: usize, P: MerkleTreeHash<F, T>> {
    perm: P,
    field: PhantomData<F>,
}

impl<F: PrimeField, const T: usize, P: MerkleTreeHash<F, T>> MerkleTree<F, T, P> {
    pub fn new(perm: P) -> Self {
        MerkleTree {
            perm,
            field: PhantomData,
        }
    }

    fn round_up_pow_n(input: usize, n: usize) -> usize {
        debug_assert!(n >= 1);
        let mut res = 1;
        // try powers, starting from n
        loop {
            res *= n;
            if res >= input {
                break;
            }
        }
        res
    }

    pub fn accumulate(&mut self, set: &[[F; T]]) -> [F; T] {
        let set_size = set.len();
        let mut bound = Self::round_up_pow_n(set_size, 2);
        loop {
            if bound >= 2 {
                break;
            }
            bound *= 2;
        }
        let mut nodes: Vec<[F; T]> = Vec::with_capacity(bound);
        for s in set {
            nodes.push(s.to_owned());
        }
        // pad
        for _ in nodes.len()..bound {
            nodes.push(nodes[set_size - 1].to_owned());
        }

        while nodes.len() > 1 {
            let new_len = nodes.len() / 2;
            let mut new_nodes: Vec<[F; T]> = Vec::with_capacity(new_len);
            for i in (0..nodes.len()).step_by(2) {
                let dig = self.perm.compress(&nodes[i], &nodes[i + 1]);
                new_nodes.push(dig);
            }
            nodes = new_nodes;
        }
        nodes[0].to_owned()
    }
}
