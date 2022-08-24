module movemate::s32x32 {
    use movemate::i128::{Self, I128};
    use movemate::i64::{Self, I64};

    struct FixedPoint32 has copy, drop, store { value: I64 }
    
    // assumes that x is already in proper FixedPoint32 form. 
    // ie, 0000 0000 0000 0000
    //     |<----->| |<----->|
    //        int       frac
    public fun fromInt(x: I128): FixedPoint32 {
        assert!(i128::compare(&x, &i128::neg_from(0x80000000)) == 2, 0);
        assert!(i128::compare(&x, &i128::from(0x7FFFFFFF)) == 1, 0);

        // convert into I64
        let a = i128::as_raw_bits(&x);
        let b  = ((a >> 32) as u64);

        FixedPoint32 {value: i64::from(b)}
    }
}