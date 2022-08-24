module movemate::s32x32 {
    use movemate::i64::{Self, I64};
    use std::debug;

    struct FixedPoint32 has copy, drop, store { value: I64 }
    
    // assumes that x is already in proper FixedPoint32 form. 
    // ie, 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000
    //     ||<---------------------------------->| |<----------------------------------->|
    //     s        int               frac
    // thus, max value is 0111 1111 1111 1111 1111 1111 1111 1111 1111 1111 1111 1111 1111 1111 1111 1111
    // or, 7FFF FFFF FFFF FFFF - which in s64x64 is 2147483647.99999999976716935634613037109375
    // min value is 1111 1111 1111 1111 1111 1111 1111 1111 1111 1111
    // or, 8000 0000 
    public fun create_from_rational(numerator: I64, denominator: I64): FixedPoint32 {
        assert!(!i64::is_zero(&denominator), 0);
        if (i64::is_zero(&numerator)) {
            return FixedPoint32 { value: i64::from(0) }
        };

        let n_sign = i64::is_neg(&numerator);
        let d_sign = i64::is_neg(&denominator);
        
        // true if pos
        let sign = (n_sign && d_sign) || (!n_sign && !d_sign);

        let a = i64::as_raw_bits(&numerator);
        let b = i64::as_raw_bits(&denominator);
 
        // zero out first bit that holds sign info, siu
        let a2 = a & 0x7FFFFFFF;
        let b2 = b & 0x7FFFFFFF;

        let a3 = (a2 as u128) << 64;
        let b3 = (b2 as u128) << 32;

        let quotient = a3 / b3;
        
        if (!sign){
            return FixedPoint32 {value: i64::neg_from((quotient as u64))}
        };

        FixedPoint32 {value: i64::from((quotient as u64))}
    }

    public fun add(a: FixedPoint32, b: FixedPoint32): FixedPoint32 {
        FixedPoint32 {value: i64::add(&a.value, &b.value) } 
    }
    public fun sub(a: FixedPoint32, b: FixedPoint32): FixedPoint32 {
        FixedPoint32 {value: i64::sub(&a.value, &b.value) } 
    }


    #[test]
    fun test_fromInt(){
        let a = i64::from(20);
        let b = i64::neg_from(10);
        let z = create_from_rational(a, b);
        debug::print(&z);
    }
}
