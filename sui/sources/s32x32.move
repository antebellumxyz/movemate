module movemate::s32x32 {
    use std::debug;

    use movemate::i64::{Self, I64};
    use movemate::i128::{Self};

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
        let a2 = a & 0x7FFFFFFFFFFFFFFF;
        let b2 = b & 0x7FFFFFFFFFFFFFFF;

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
    public fun mul(a: FixedPoint32, b: FixedPoint32): FixedPoint32 {

        // should cast up into i128
        let a1 = i128::fromI64(&a.value);
        let b1 = i128::fromI64(&b.value);

        let r = i128::mul(&a1, &b1);

        let sign = i128::is_neg(&r);

        let r1 = i128::as_raw_bits(&i128::abs(&r));

        if (sign) {
            return FixedPoint32 {value: i64::neg_from(((r1 >> 32) as u64))} 
        };

        FixedPoint32 {value: i64::from(((r1 >> 32) as u64))} 
    }

    public fun div(a: FixedPoint32, b: FixedPoint32): FixedPoint32 {
        assert!(i64::is_zero(&b.value) != true, 0);

        let n_sign = i64::is_neg(&a.value);
        let d_sign = i64::is_neg(&b.value);
        
        // true if pos
        let sign = (n_sign && d_sign) || (!n_sign && !d_sign);

        let a1 = i64::as_raw_bits(&a.value);
        let b1 = i64::as_raw_bits(&b.value);
        //debug::print(&a1);
        //debug::print(&b1);
        // zero out first bit that holds sign info, siu
        let a2 = a1 & 0x7FFFFFFFFFFFFFFF;
        let b2 = b1 & 0x7FFFFFFFFFFFFFFF;

        //debug::print(&a2);
        //debug::print(&b2);

        let a3 = i128::from((a2 as u128) << 32);
        let b3 = i128::from((b2 as u128));
        //debug::print(&a3);
        //debug::print(&b3);

        let result = i128::as_raw_bits(&i128::div(&a3, &b3));
        if (!sign) {
            return FixedPoint32 {value: i64::neg_from((result as u64))}
        };

        FixedPoint32{value: i64::from((result as u64))}
    }

    public fun abs(a: FixedPoint32): FixedPoint32 {
        FixedPoint32 {value: i64::abs(&a.value)}
    }

    public fun neg(a: FixedPoint32): FixedPoint32 {
        FixedPoint32 {value: i64::neg(&a.value)}
    }
    
    public fun get_raw_bits(a: FixedPoint32): u64 {
        i64::as_raw_bits(&a.value)
    }

    // Calculate the sqrt(x) rounding down, where x is unsigned 64 bit int num
    public fun sqrtu (a: u128): u64 {

        let xx: u128 = a;
        let r: u128 = 1;
        
        if (xx >= 0x10000000000000000) { xx = xx >> 64; r = r << 32; };
        if (xx >= 0x100000000) { xx = xx >> 32; r = r << 16; };

        if (xx >= 0x10000) {xx = xx >> 16; r = r << 8; };
        if (xx >= 0x100) { xx = xx >> 8; r = r << 4; };

        if (xx >= 0x10) { xx = xx >> 4; r = r << 2; };

        if (xx >= 0x8) { r = r << 1; };

        r = (r + a / r) >> 1;
        r = (r + a / r) >> 1;
        r = (r + a / r) >> 1;
        r = (r + a / r) >> 1;
        r = (r + a / r) >> 1;
        r = (r + a / r) >> 1;

        let r1: u128 = a / r;
        if(r < r1)
        {
            return (r as u64)
        };
        return (r1 as u64)
    }

    public fun sqrt(a: FixedPoint32): FixedPoint32 {
        assert!(i64::is_zero(&a.value) != true, 0);
        assert!(i64::is_neg(&a.value) != true, 0);

        let c = (i64::as_u64(&i64::abs(&a.value)) as u128);

        debug::print(&c);

        let something = sqrtu(c);
        debug::print(&something);
        FixedPoint32{value: i64::from((something as u64) << 16)}
    }

    #[test]
    fun test_create_from_rational(){
        //let a = i64::from(20);
        //let b = i64::neg_from(10);
        //let z = create_from_rational(a, b);
        
        //debug::print(&z);
    }

    #[test]
    fun test_mul() {
        let z = create_from_rational(i64::from(4), i64::from(1));
        let x = create_from_rational(i64::from(4), i64::neg_from(2)); 
        let result = mul(z, x);
        assert!(get_raw_bits(result) == get_raw_bits(create_from_rational(i64::neg_from(8), i64::from(1))), 0);

        let z = create_from_rational(i64::from(1), i64::from(2));
        let x = create_from_rational(i64::from(4), i64::neg_from(2)); 
        let result = mul(z, x);
        assert!(get_raw_bits(result) == get_raw_bits(create_from_rational(i64::neg_from(1), i64::from(1))), 0);

        let z = create_from_rational(i64::from(1), i64::neg_from(2));
        let x = create_from_rational(i64::from(4), i64::neg_from(2)); 
        let result = mul(z, x);
        assert!(get_raw_bits(result) == get_raw_bits(create_from_rational(i64::from(1), i64::from(1))), 0);

        let z = create_from_rational(i64::from(1), i64::from(2));
        let x = create_from_rational(i64::from(4), i64::from(2)); 
        let result = mul(z, x);
        assert!(get_raw_bits(result) == get_raw_bits(create_from_rational(i64::from(1), i64::from(1))), 0);
    }

    #[test]
    fun test_div() {
        let z = create_from_rational(i64::from(4), i64::from(1));
        let x = create_from_rational(i64::from(8), i64::neg_from(1)); 
        let result = div(z, x);
        assert!(get_raw_bits(result) == get_raw_bits(create_from_rational(i64::neg_from(1), i64::from(2))), 0);
    }

    #[test]
    fun test_sqrt() {
        let z = create_from_rational(i64::from(1), i64::from(69));
        debug::print(&z);

        let result = sqrt(z);
        debug::print(&result);
    }
}
