/// @title fixed_point64
/// @notice fixed-point numeric type implemented with u128.
/// @dev todo this spec schema stuff? (cant find in docs) in https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/deps/move-stdlib/sources/fixed_point32.move

module movemate::fixed_point64 {
    use std::errors;
    use movemate::u256::{Self};
    use movemate::math_u128::{Self};

    //use std::debug;

    /// @dev max value a `u128` can take.
    const U128_MAX: u128 = 340282366920938463463374607431768211455;

    /// @dev max value a `u64` can take.
    const U64_MAX: u128 = 18446744073709551615;

    /// @dev 
    const RESOLUTION: u8 = 64;

    /// @dev 000000000000000000FFFFFFFFFFFFFFFF captures the 64 lower bits 
    const LOWER_MASK: u128 = 0xFFFFFFFFFFFFFFFF;

    /// @dev 
    const Q64: u128 = 0x10000000000000000; // 2^64

    /// @dev demoninator provided was zero
    const EDENOMINATOR:u64 = 0;
    /// @dev quotient value would be too large to be held in a `u128`
    const EDIVISION: u64 = 1;
    /// @dev multiplicated value would be too lrage to be held in a `u128`
    const EMULTIPLICATION: u64 = 2;
    /// @dev division by zero error
    const EDIVISION_BY_ZERO: u64 = 3;
    /// @dev computed ratio when converting to a `FixedPoint64` would be unrepresentable
    const ERATIO_OUT_OF_RANGE: u64 = 4;

    /// @notice struct representing a fixed-point numeric type with 64 fractional bits
    struct FixedPoint64 has copy, drop, store {
        value: u128
    } 

    /// @notice creates a `FixedPoint64` object from a `u128` numerator and denominator. 
    public fun create_from_rational(numerator: u128, denominator: u128): FixedPoint64 {
        // make both u256 to ensure no overflow when dividing.
        let cast_numerator = u256::from_u128(numerator);
        let cast_denominator = u256::from_u128(denominator);
     
        let scaled_numerator = u256::shl(cast_numerator, 128);
        let scaled_denominator = u256::shl(cast_denominator, 64);

        // U256 module throws error on overflow. 
        let result = u256::div(scaled_numerator, scaled_denominator);

        let quotient = u256::as_u128(result);

        assert!(quotient != 0 || numerator == 0, errors::invalid_argument(ERATIO_OUT_OF_RANGE));

        FixedPoint64 { value: quotient }
    }

    /// @notice multiply a u128 integer by a `FixedPoint64` multiplier
    public fun multiply_u128(val: u128, multiplier: FixedPoint64): u128 {
        let unscaled_product = u256::mul(
            u256::from_u128(val), 
            u256::from_u128(multiplier.value)
        );

        // unscaled product has 128 fractional bits, so need to rescale by rshifting
        let product = u256::as_u128(u256::shr(unscaled_product, 64));
        
        product
    }

    public fun add(a: FixedPoint64, b: FixedPoint64): FixedPoint64 {
        FixedPoint64 { value: a.value + b.value }
    }

    /// @notice divide a u128 integer by a `FixedPoint64` multiplier
    public fun divide_u128(val: u128, divisor: FixedPoint64): u128 {
        let scaled_div = u256::shl(u256::from_u128(val), 64);
        let quotient = u256::as_u128(u256::div(scaled_div, u256::from_u128(divisor.value)));

        quotient
    }

    /// @notice multiply a `FixedPoint64` by another `FixedPoint64`.
    public fun multiply(a: FixedPoint64, b: FixedPoint64): FixedPoint64 {
        if (a.value == 0 || b.value == 0) {
            return FixedPoint64 { value: 0 }
        };


        let upper_a = ((a.value >> RESOLUTION) as u64);
        let upper_b = ((b.value >> RESOLUTION) as u64);
        let lower_a = ((a.value & LOWER_MASK) as u64);
        let lower_b = ((b.value & LOWER_MASK) as u64);

        // partial products
        let upper: u128 = (upper_a as u128) * (upper_b as u128);
        let lower: u128 = (lower_a as u128) * (lower_b as u128);
        let uppera_lowerb: u128 = (upper_a as u128) * (lower_b as u128);
        let upperb_lowera: u128 = (upper_b as u128) * (lower_a as u128);

        assert!(upper <= U64_MAX, 0);

        // handles overflow, above can prob be removed?
        let sum = (upper << RESOLUTION) + uppera_lowerb + upperb_lowera + (lower >> RESOLUTION);

        FixedPoint64 {value: sum}
    }

    /// @notice divide a `FixedPoint64` by another `FixedPoint64`
    public fun divide(a: FixedPoint64, b: FixedPoint64): FixedPoint64 {
        assert!(b.value > 0, 0);
        if (a.value == b.value) {
            return FixedPoint64 {value: 0x8000000000000000 }
        };
        if (a.value <= U64_MAX){
            let value: u128 = (a.value << RESOLUTION) / b.value; 
            return FixedPoint64 { value }
        };
        let value = math_u128::mul_div(Q64, a.value, b.value);
        FixedPoint64 { value }
    }

    /// @notice Casts raw `u128` value to `FixedPoint64` 
    public fun create_from_raw_value(value: u128): FixedPoint64 {
        FixedPoint64 { value }
    }

    /// @notice take a FixedPoint64 to a integer power. fails on overflow within the multiply function.
    /// lossy between 0/1 and 40 bits
    public fun pow(a: FixedPoint64, b: u128): FixedPoint64 {
        let result = create_from_rational(1, 1);
        while (b > 0) {
            result = multiply(result, a);
            b = b - 1;
        };
        result
    }


    /// @notice power exponential function in embedded system
    /// https://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=6521197
    // public fun exp(a: FixedPoint64, b: FixedPoint64) {

    // }

    /// @notice take the reciprocal of a `FixedPoint64`
    public fun reciprocal(a: FixedPoint64): FixedPoint64{
        assert!(a.value != 0, 0);
        assert!(a.value != 1, 1);
        FixedPoint64 { value: Q64 / a.value }
    }   

    /// @notice Get value in `FixedPoint64` 
    public fun get_raw_value(num: FixedPoint64): u128 {
        num.value
    }

    /// @notice Check `FixedPoint64` value is zero
    public fun is_zero(num: FixedPoint64): bool {
        num.value == 0
    }

    #[test]
    fun test_create_raw(){
        let test_fixed = create_from_raw_value(1099494850560);
        assert!(get_raw_value(test_fixed) == 1099494850560, 0)
    }

    #[test]
    fun test_create_rational() {
        // 1/2 is 0.5, so the hex should look like [0000 0000 0000 0000].[8000 0000 0000 0000]  
        // since 8000 = 1000 0000 0000 0000 => 1/2 + 0/4 + 0/8 + ... = 0.5
        assert!(get_raw_value(create_from_rational(1, 2)) == 0x8000000000000000, 4);
        assert!(get_raw_value(create_from_rational(1, 3)) == 0x5555555555555555, 4);
        assert!(get_raw_value(create_from_rational(2, 4)) == 0x8000000000000000, 4);
        assert!(get_raw_value(create_from_rational(0x10000000000000000, 0x20000000000000000)) == 0x8000000000000000, 4);
    }

    #[test]
    fun test_create_big_rational() {
        // should be 1.0, ie 1 0000 0000 0000 0000
        assert!(get_raw_value(create_from_rational(U128_MAX, U128_MAX)) == 0x10000000000000000, 4);
    }

    #[test]
    #[expected_failure(abort_code = 3)]
    fun test_rational_zero_denom() {
        create_from_rational(1, 0);
    }


    #[test]
    fun test_zero_mul(){
        let multiplier = create_from_rational(0, 1);
        assert!(multiply_u128(5, multiplier) == 0, 2);

    }

    #[test] 
    fun test_multiplication() {
        let multiplier = create_from_rational(5, 1);
        assert!(multiply_u128(5, multiplier) == 25, 2);

        // note 5 * 1/5 rounds down to zero since its represented as 0000 0000 0000 0000 1111 1111 1111 1111 or 0.9999....
        assert!(multiply_u128(5, create_from_rational(1, 5)) == 0, 2);
        assert!(multiply_u128(5, create_from_rational(1, 2)) == 2, 2);
    }

    #[test]
    #[expected_failure(abort_code = 0)]
    fun test_multiplication_overflow() {
        assert!(multiply_u128(U128_MAX, create_from_rational(2, 1)) == 0, 2);
    }

    // test asserts result is 1 when n/d where n = 5 and d = 5
    #[test]
    fun test_division_whole() {
        // create divisor
        let divisor = create_from_rational(5, 1);
        // assert test result is 5
        assert!(divide_u128(5, divisor) == 1, 1);
    }

    // test asserts result is 10 when n/d where n = 5 and d = 1/2
    #[test]
    fun test_division_fraction() {
        // create divisor
        let divisor = create_from_rational(1, 2);
        // assert test result is 10
        assert!(divide_u128(5, divisor) == 10, 1);
    }

    // test asserts result is 0 when n/d where n = 1 and d = 2
    #[test]
    fun test_division_zero() {
        // create divisor
        let divisor = create_from_rational(2, 1);
        // assert test result is zero
        assert!(divide_u128(1, divisor) == 0, 1);
    }

    #[test]
    fun test_fixed_by_fixed_mul() {
        let a = create_from_rational(5, 1);
        let b = create_from_rational(1, 2);

        assert!(multiply(a, b) == multiply(b, a), 2);
        // 2.5 is 0000 0000 0000 0002 8000 0000 0000 0000 in fixedpoint rep
        assert!(get_raw_value(multiply(a, b)) == 0x28000000000000000, 2);

        let zero = create_from_rational(0,1);
        assert!(get_raw_value(multiply(a, zero)) == 0, 2);
    }

    #[test]
    #[expected_failure(abort_code = 0)]
    fun test_fixed_by_fixed_overflow() {
        let max_one = create_from_rational(U64_MAX, 1);
        let multiplier = create_from_rational(2, 1);
        multiply(max_one, multiplier);
    }

    #[test]
    fun test_fixed_by_fixed_limits() {
        let max_one = create_from_rational(U64_MAX, 1);
        let multiplier = create_from_rational(1, U64_MAX);
        assert!(get_raw_value(multiply(max_one, multiplier)) == 0xFFFFFFFFFFFFFFFF, 1);
    }
    
    #[test]
    fun test_fxf_divide() {
        let a = create_from_rational(5, 1);
        let b = create_from_rational(2, 1);

        assert!(get_raw_value(divide(a, b)) == 0x28000000000000000, 2);
    }

    #[test]
    fun test_pow() {
        let a = create_from_rational(3, 2);
        let b: u128 = 8; 
        assert!(get_raw_value(pow(a, b)) == 0x19A100000000000000, 0);
    }

    #[test]
    #[expected_failure(abort_code = 0)]
    fun test_overflow_pow() {
        let a = create_from_rational(100, 1);
        let b = 200;
        pow(a, b);
    }
}