#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# Extracts the benchmarks after running:
# RUSTFLAGS="-C target-cpu=native -C target-feature=-avx512f" cargo +nightly bench --bench plain_goldilocks --bench plain_mersenne

from itertools import takewhile
import sys
import math


def round_half_up(n, decimals=0):
    multiplier = 10 ** decimals
    s = str(math.floor(n * multiplier + 0.5) / multiplier)
    index = s.find(".")
    if index == -1:
        s = s + ".0"
    return s


def get_file(path):
    output = ""
    with open(path, "r") as f:
        output = f.read()
    return output


def parse(file_out, prefix, postfix, start_index):
    index1 = find_index(file_out, prefix, start_index)
    index2 = find_index(file_out, postfix, index1 + len(prefix) + 1)
    output = file_out[index1 + len(prefix):index2]
    return output


def find_index(string, find_string, start_index=0):
    index = string.find(find_string, start_index)
    if (index == -1):
        s = "index not found in output: {}".format(find_string)
        raise RuntimeError(s)
    return index


def print_dict(dic):
    for el in dic:
        print("{};".format(el["name"]), end="")
        print("{};".format(el["average"]), end="")
        print("{};".format(el["average unit"]), end="")
        print()


def to_ns(time, unit):
    if unit == "ns":
        return round_half_up(float(time), 1)
    elif unit == "µs":
        return round_half_up(float(time) * 1000, 1)
    else:
        s = "unsupported unit: {}".format(unit)
        raise RuntimeError(s)


def get_ns(dic, cipher, t, prime, op, lookup, constant_time):
    for el in dic:
        if el["cipher"] == cipher and el["t"] == t and el["prime"] == prime and el["op"] == op and el["lookup"] == lookup and el["constant_time"] == constant_time and el["name"].find("Winterfell") == -1:
            return to_ns(el["average"], el["average unit"])
    s = "not found in dictionary"
    raise RuntimeError(s)


def print_main_table(dic):
    print("\\begin{tabular}{lrr}")
    print("  \\toprule")
    print(
        "  \\multirow{2}{*}{Hashing algorithm} & \\multicolumn{2}{c}{Time for one permutation ($ns$)}\\\\")
    print("  & 2-to-1 compression  & sponge \\\\")

    print("  \\midrule")
    print("  $p=2^{64}-2^{32}+1$: & $t=8$ & $t=12$ \\\\")
    print("  \\midrule")

    fmt = " & {} & {} \\\\"

    ns_8 = get_ns(dic, "Monolith", 8,
                  "F64", "Permutation", False, False)
    ns_12 = get_ns(dic, "Monolith", 12,
                   "F64", "Permutation", False, False)
    print("    \\designpermBig{}" + fmt.format(ns_8, ns_12))

    ns_8 = get_ns(dic, "Poseidon", 8,
                  "F64", "Permutation", False, False)
    ns_12 = get_ns(dic, "Poseidon", 12,
                   "F64", "Permutation", False, False)
    print("    \\poseidon " + fmt.format(ns_8, ns_12))

    ns_8 = get_ns(dic, "Poseidon2", 8,
                  "F64", "Permutation", False, False)
    ns_12 = get_ns(dic, "Poseidon2", 12,
                   "F64", "Permutation", False, False)
    print("    \\poseidonnew " + fmt.format(ns_8, ns_12))

    ns_8 = get_ns(dic, "Rescue", 8,
                  "F64", "Permutation", False, False)
    ns_12 = get_ns(dic, "Rescue", 12,
                   "F64", "Permutation", False, False)
    print("    \\rescue-Prime " + fmt.format(ns_8, ns_12))

    ns_8 = get_ns(dic, "Griffin", 8,
                  "F64", "Permutation", False, False)
    ns_12 = get_ns(dic, "Griffin", 12,
                   "F64", "Permutation", False, False)
    print("    \\griffin" + fmt.format(ns_8, ns_12))

    ns_8 = get_ns(dic, "Neptune", 8,
                  "F64", "Permutation", False, False)
    ns_12 = get_ns(dic, "Neptune", 12,
                   "F64", "Permutation", False, False)
    print("    \\neptune" + fmt.format(ns_8, ns_12))

    ns_8 = get_ns(dic, "GMiMC", 8,
                  "F64", "Permutation", False, False)
    ns_12 = get_ns(dic, "GMiMC", 12,
                   "F64", "Permutation", False, False)
    print("    \\gmimc" + fmt.format(ns_8, ns_12))

    fmt = " & & {} \\\\"

    ns_16 = get_ns(dic, "Tip5", 16,
                   "F64", "Permutation", False, False)
    print("    \\tipfive{} ($t=16$)" + fmt.format(ns_16))

    ns_12 = get_ns(dic, "Tip4'", 12,
                   "F64", "Permutation", False, False)
    print("    \\tipfour{}$^\prime$" +
          fmt.format(ns_12))

    ns_16 = get_ns(dic, "Rescue", 16,
                   "F64", "Permutation", False, False)
    print("    \\rescue-Prime Optimized ($t=16$)" +
          fmt.format(ns_16))

    print("  \\midrule")
    print("  $p=2^{31}-1$: & $t=16$ & $t=24$ \\\\")
    print("  \\midrule")

    fmt = " & {} & {} \\\\"

    ns_16 = get_ns(dic, "Monolith", 16,
                   "F31", "Permutation", False, False)
    ns_24 = get_ns(dic, "Monolith", 24,
                   "F31", "Permutation", False, False)
    print("    \\designpermSmall{}" +
          fmt.format(ns_16, ns_24))

    ns_16 = get_ns(dic, "Poseidon", 16,
                   "F31", "Permutation", False, False)
    ns_24 = get_ns(dic, "Poseidon", 24,
                   "F31", "Permutation", False, False)
    print("    \\poseidon" +
          fmt.format(ns_16, ns_24))

    ns_16 = get_ns(dic, "Poseidon2", 16,
                   "F31", "Permutation", False, False)
    ns_24 = get_ns(dic, "Poseidon2", 24,
                   "F31", "Permutation", False, False)
    print("    \\poseidonnew" +
          fmt.format(ns_16, ns_24))

    print("  \\midrule")
    print("  \\multicolumn{3}{l}{Other:} \\\\")
    print("  \\midrule")

    # Values are from the "hashes" benchmarks
    print("    \\reinforcedconcrete{} (BN254) & & 1467.1 \\\\")
    print("    SHA3-256 & & 189.8 \\\\")
    print("    SHA-256 & 45.3 & \\\\")

    print("  \\bottomrule")
    print("\\end{tabular}")
    print()


def print_const_table(dic):
    print("\\begin{tabular}{lrrrr}")
    print("  \\toprule")
    print(
        "  \multirow{2}{*}{Hashing algorithm} & \\multicolumn{4}{c}{Time ($ns$)}\\\\")
    print("  & $t=8$ & $t=12$ & $t=16$ & $t=24$ \\\\")

    print("  \\midrule")
    print("  \\multicolumn{5}{l}{$p=2^{64}-2^{32}+1$:} \\\\")
    print("  \\midrule")

    fmt = " & {} & {} & & \\\\"

    ns_8 = get_ns(dic, "Monolith", 8,
                  "F64", "Permutation", False, True)
    ns_12 = get_ns(dic, "Monolith", 12,
                   "F64", "Permutation", False, True)
    print("    \\designpermBig{}" + fmt.format(ns_8, ns_12))

    ns_8 = get_ns(dic, "Poseidon", 8,
                  "F64", "Permutation", False, True)
    ns_12 = get_ns(dic, "Poseidon", 12,
                   "F64", "Permutation", False, True)
    print("    \\poseidon " + fmt.format(ns_8, ns_12))

    ns_8 = get_ns(dic, "Poseidon2", 8,
                  "F64", "Permutation", False, True)
    ns_12 = get_ns(dic, "Poseidon2", 12,
                   "F64", "Permutation", False, True)
    print("    \\poseidonnew " + fmt.format(ns_8, ns_12))

    print("  \\midrule")
    print("  \\multicolumn{5}{l}{$p=2^{31}-1$:} \\\\")
    print("  \\midrule")

    fmt = " & & & {} & {} \\\\"

    ns_16 = get_ns(dic, "Monolith", 16,
                   "F31", "Permutation", False, True)
    ns_24 = get_ns(dic, "Monolith", 24,
                   "F31", "Permutation", False, True)
    print("    \\designpermSmall{}" +
          fmt.format(ns_16, ns_24))

    ns_16 = get_ns(dic, "Poseidon", 16,
                   "F31", "Permutation", False, True)
    ns_24 = get_ns(dic, "Poseidon", 24,
                   "F31", "Permutation", False, True)
    print("    \\poseidon" +
          fmt.format(ns_16, ns_24))

    ns_16 = get_ns(dic, "Poseidon2", 16,
                   "F31", "Permutation", False, True)
    ns_24 = get_ns(dic, "Poseidon2", 24,
                   "F31", "Permutation", False, True)
    print("    \\poseidonnew" +
          fmt.format(ns_16, ns_24))

    print("  \\bottomrule")
    print("\\end{tabular}")
    print()


def print_op_table(dic):
    print("\\begin{tabular}{lrrrr|rrrr}")
    print("  \\toprule")
    print(
        "  \\multirow{2}{*}{Operation} & \\multicolumn{4}{c|}{Time ($ns$)} & \\multicolumn{4}{c}{Const. Time ($ns$)} \\\\")
    print("  & $t=8$ & $t=12$ & $t=16$ & $t=24$ & $t=8$ & $t=12$ & $t=16$ & $t=24$ \\\\")

    print("  \\midrule")
    print("  \\multicolumn{5}{l}{$p=2^{64}-2^{32}+1$:} \\\\")
    print("  \\midrule")

    fmt = " & {} & {} & & & {} & {} & & \\\\"

    ns_8 = get_ns(dic, "Monolith", 8,
                  "F64", "Concrete", False, False)
    ns_12 = get_ns(dic, "Monolith", 12,
                   "F64", "Concrete", False, False)
    ns_8_c = get_ns(dic, "Monolith", 8,
                    "F64", "Concrete", False, True)
    ns_12_c = get_ns(dic, "Monolith", 12,
                     "F64", "Concrete", False, True)
    print("    \\concrete" +
          fmt.format(ns_8, ns_12, ns_8_c, ns_12_c))

    ns_8 = get_ns(dic, "Monolith", 8,
                  "F64", "Bricks", False, False)
    ns_12 = get_ns(dic, "Monolith", 12,
                   "F64", "Bricks", False, False)
    ns_8_c = get_ns(dic, "Monolith", 8,
                    "F64", "Bricks", False, True)
    ns_12_c = get_ns(dic, "Monolith", 12,
                     "F64", "Bricks", False, True)
    print("    \\bricks" +
          fmt.format(ns_8, ns_12, ns_8_c, ns_12_c))

    ns_8 = get_ns(dic, "Monolith", 8,
                  "F64", "Bars", False, False)
    ns_12 = get_ns(dic, "Monolith", 12,
                   "F64", "Bars", False, False)
    ns_8_c = get_ns(dic, "Monolith", 8,
                    "F64", "Bars", False, True)
    ns_12_c = get_ns(dic, "Monolith", 12,
                     "F64", "Bars", False, True)
    print("    \\bars" +
          fmt.format(ns_8, ns_12, ns_8_c, ns_12_c))

    print("  \\midrule")
    print("  \\multicolumn{5}{l}{$p=2^{31}-1$:} \\\\")
    print("  \\midrule")

    fmt = " & & & {} & {} & & & {} & {} \\\\"

    ns_16 = get_ns(dic, "Monolith", 16,
                   "F31", "Concrete", False, False)
    ns_24 = get_ns(dic, "Monolith", 24,
                   "F31", "Concrete", False, False)
    ns_16_c = get_ns(dic, "Monolith", 16,
                     "F31", "Concrete", False, True)
    ns_24_c = get_ns(dic, "Monolith", 24,
                     "F31", "Concrete", False, True)
    print("    \\concrete" +
          fmt.format(ns_16, ns_24, ns_16_c, ns_24_c))

    ns_16 = get_ns(dic, "Monolith", 16,
                   "F31", "Bricks", False, False)
    ns_24 = get_ns(dic, "Monolith", 24,
                   "F31", "Bricks", False, False)
    ns_16_c = get_ns(dic, "Monolith", 16,
                     "F31", "Bricks", False, True)
    ns_24_c = get_ns(dic, "Monolith", 24,
                     "F31", "Bricks", False, True)
    print("    \\bricks" +
          fmt.format(ns_16, ns_24, ns_16_c, ns_24_c))

    ns_16 = get_ns(dic, "Monolith", 16,
                   "F31", "Bars", False, False)
    ns_24 = get_ns(dic, "Monolith", 24,
                   "F31", "Bars", False, False)
    ns_16_c = get_ns(dic, "Monolith", 16,
                     "F31", "Bars", False, True)
    ns_24_c = get_ns(dic, "Monolith", 24,
                     "F31", "Bars", False, True)
    print("    \\bars" +
          fmt.format(ns_16, ns_24, ns_16_c, ns_24_c))

    print("  \\bottomrule")
    print("\\end{tabular}")
    print()


def print_rc_variants_t(dic, t):
    f = 64
    if t > 12:
        f = 31

    print("Monolith-{}, t={}:".format(f, t))

    print("  Perm:")
    ns = get_ns(dic, "Monolith", t,
                "F" + str(f), "Permutation", False, False)
    ns_l = get_ns(dic, "Monolith", t,
                  "F" + str(f), "Permutation", True, False)
    ns_c = get_ns(dic, "Monolith", t,
                  "F" + str(f), "Permutation", False, True)
    ns_c_l = get_ns(dic, "Monolith", t,
                    "F" + str(f), "Permutation", True, True)
    print("    standard     : " + str(ns))
    print("    lookup       : " + str(ns_l))
    print("    constant time: " + str(ns_c))
    print("    lookup const : " + str(ns_c_l))

    print("  Concrete:")
    ns = get_ns(dic, "Monolith", t,
                "F" + str(f), "Concrete", False, False)
    ns_c = get_ns(dic, "Monolith", t,
                  "F" + str(f), "Concrete", False, True)
    print("    standard     : " + str(ns))
    print("    constant time: " + str(ns_c))

    print("  Bricks:")
    ns = get_ns(dic, "Monolith", t,
                "F" + str(f), "Bricks", False, False)
    ns_c = get_ns(dic, "Monolith", t,
                  "F" + str(f), "Bricks", False, True)
    print("    standard     : " + str(ns))
    print("    constant time: " + str(ns_c))

    print("  Bars:")
    ns = get_ns(dic, "Monolith", t,
                "F" + str(f), "Bars", False, False)
    ns_l = get_ns(dic, "Monolith", t,
                  "F" + str(f), "Bars", True, False)
    ns_c = get_ns(dic, "Monolith", t,
                  "F" + str(f), "Bars", False, True)
    print("    standard     : " + str(ns))
    print("    lookup       : " + str(ns_l))
    print("    constant time: " + str(ns_c))
    print()


def print_rc_variants(dic):
    print_rc_variants_t(dic, 8)
    print_rc_variants_t(dic, 12)
    print_rc_variants_t(dic, 16)
    print_rc_variants_t(dic, 24)


def parse_file(file_out):
    analyze_str = "Analyzing\n"
    benchmark_str = "Benchmarking "
    result = []
    index = -1
    while True:
        index = file_out.find(benchmark_str, index + 1)
        if (index == -1):
            break

        bench_name = parse(file_out, benchmark_str, "\n", index)
        index = find_index(file_out, analyze_str, index + 1)
        times = parse(file_out, "[", "]", index).split()

        t = "?"
        index_ = bench_name.find("t = ")
        if index_ == -1:
            index_ = bench_name.find("t=")
            if index_ != -1:
                t = int(
                    ''.join(takewhile(str.isdigit,  bench_name[index_ + 2:])))
        else:
            t = int(''.join(takewhile(str.isdigit,  bench_name[index_ + 4:])))

        prime = "?"
        if bench_name.find("Goldilocks") != -1 or bench_name.find("F64") != -1 or bench_name.startswith("Tip") or bench_name.startswith("Rescue Prime optimized"):
            prime = "F64"
        elif bench_name.find("Mersenne") != -1 or bench_name.find("F31") != -1:
            prime = "F31"

        constant_time = False
        if bench_name.find("constant time") != -1:
            constant_time = True

        op = "Permutation"
        if bench_name.find("Bars") != -1:
            op = "Bars"
        elif bench_name.find("Bar") != -1:
            op = "Bar"
        elif bench_name.find("Bricks") != -1:
            op = "Bricks"
        elif bench_name.find(" Concrete") != -1:
            op = "Concrete"

        lookup = False
        if bench_name.find("Lookup") != -1:
            lookup = True

        r = {}
        r["name"] = bench_name
        r["cipher"] = bench_name.split(" ")[0]
        r["t"] = t
        r["prime"] = prime
        r["op"] = op
        r["lookup"] = lookup
        r["constant_time"] = constant_time
        r["min"] = times[0]
        r["min unit"] = times[1]
        r["average"] = times[2]
        r["average unit"] = times[3]
        r["max"] = times[4]
        r["max unit"] = times[5]
        result.append(r)
    return result


def main():
    if (len(sys.argv) != 2):
        print("Usage: " + sys.argv[0] + " <path>")
        return -1

    file_out = get_file(sys.argv[1])
    dic = parse_file(file_out)
    # print_dict(dic)
    # print_main_table(dic)
    # print_const_table(dic)
    # print_op_table(dic)

    print_rc_variants(dic)


if __name__ == "__main__":
    sys.exit(main())
