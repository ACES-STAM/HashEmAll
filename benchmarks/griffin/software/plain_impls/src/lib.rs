//! # zkhash
//!
//! A pure Rust implementation of the ReinforcedConcrete Permutation
#![cfg_attr(feature = "asm", feature(asm))]

pub extern crate ff;


pub mod fields;
pub mod griffin;
pub mod merkle_tree;
pub mod utils;
