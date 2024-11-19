use lazy_static::lazy_static;
use std::sync::Arc;

use crate::{
    fields::{bls12::FpBLS12, bn256::FpBN256, bn254::FpBN254, f64::F64, st::FpST},
    griffin::griffin_params::GriffinParams,
};

lazy_static! {
    // BN256
    pub static ref GRIFFIN_BN_PARAMS: Arc<GriffinParams<FpBN256>> = Arc::new(GriffinParams::new(3, 5, 12));
    // BLS12
    pub static ref GRIFFIN_BLS_PARAMS: Arc<GriffinParams<FpBLS12>> = Arc::new(GriffinParams::new(3, 5, 12));
    // ST
    pub static ref GRIFFIN_ST_PARAMS: Arc<GriffinParams<FpST>> = Arc::new(GriffinParams::new(3, 3, 16));
    // Goldilocks
    pub static ref GRIFFIN_GOLDILOCKS_8_PARAMS: Arc<GriffinParams<F64>> = Arc::new(GriffinParams::new(8, 7,  8));
    pub static ref GRIFFIN_GOLDILOCKS_12_PARAMS: Arc<GriffinParams<F64>> = Arc::new(GriffinParams::new(12, 7, 8));
    
    // BN254 - New instance for BN254 curve
    pub static ref GRIFFIN_BN254_PARAMS: Arc<GriffinParams<FpBN254>> = Arc::new(GriffinParams::new(3, 5, 14));
}


