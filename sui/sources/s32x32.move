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

     /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  public fun exp_2(x: u64): u64 {
        assert!(x < 0x7FFFFFFFFFFFFFFF, 0);

        let result: u128 = 0x8000000000000000;

    //   if (x & 0x4000000000000000 > 0)
    //     result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 64;
    //   if (x & 0x2000000000000000 > 0)
    //     result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 64;
    //   if (x & 0x1000000000000000 > 0)
    //     result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 64;
    //   if (x & 0x800000000000000 > 0)
    //     result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 64;
    //   if (x & 0x400000000000000 > 0)
    //     result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 64;
    //   if (x & 0x200000000000000 > 0)
    //     result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 64;
    //   if (x & 0x100000000000000 > 0)
    //     result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 64;
    //   if (x & 0x80000000000000 > 0)
    //     result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 64;
    //   if (x & 0x40000000000000 > 0)
    //     result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 64;
    //   if (x & 0x20000000000000 > 0)
    //     result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 64;
    //   if (x & 0x10000000000000 > 0)
    //     result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 64;
    //   if (x & 0x8000000000000 > 0)
    //     result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 64;
    //   if (x & 0x4000000000000 > 0)
    //     result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 64;
    //   if (x & 0x2000000000000 > 0)
    //     result = result * 0x1000162E525EE054754457D5995292026 >> 64;
    //   if (x & 0x1000000000000 > 0)
    //     result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 64;
    //   if (x & 0x800000000000 > 0)
    //     result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 64;
    //   if (x & 0x400000000000 > 0)
    //     result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 64;
    //   if (x & 0x200000000000 > 0)
    //     result = result * 0x10000162E43F4F831060E02D839A9D16D >> 64;
    //   if (x & 0x100000000000 > 0)
    //     result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 64;
    //   if (x & 0x80000000000 > 0)
    //     result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 64;
    //   if (x & 0x40000000000 > 0)
    //     result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 64;
    //   if (x & 0x20000000000 > 0)
    //     result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 64;
    //   if (x & 0x10000000000 > 0)
    //     result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 64;
    //   if (x & 0x8000000000 > 0)
    //     result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 64;
    //   if (x & 0x4000000000 > 0)
    //     result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 64;
    //   if (x & 0x2000000000 > 0)
    //     result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 64;
    //   if (x & 0x1000000000 > 0)
    //     result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 64;
    //   if (x & 0x800000000 > 0)
    //     result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 64;
    //   if (x & 0x400000000 > 0)
    //     result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 64;
    //   if (x & 0x200000000 > 0)
    //     result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 64;
    //   if (x & 0x100000000 > 0)
    //     result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 64;
    //   if (x & 0x80000000 > 0)
    //     result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 64;
    //   if (x & 0x40000000 > 0)
    //     result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 64;
    //   if (x & 0x20000000 > 0)
    //     result = result * 0x100000000162E42FEFB2FED257559BDAA >> 64;
    //   if (x & 0x10000000 > 0)
    //     result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 64;
    //   if (x & 0x8000000 > 0)
    //     result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 64;
    //   if (x & 0x4000000 > 0)
    //     result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 64;
    //   if (x & 0x2000000 > 0)
    //     result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 64;
    //   if (x & 0x1000000 > 0)
    //     result = result * 0x10000000000B17217F7D20CF927C8E94C >> 64;
    //   if (x & 0x800000 > 0)
    //     result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 64;
    //   if (x & 0x400000 > 0)
    //     result = result * 0x100000000002C5C85FDF477B662B26945 >> 64;
    //   if (x & 0x200000 > 0)
    //     result = result * 0x10000000000162E42FEFA3AE53369388C >> 64;
    //   if (x & 0x100000 > 0)
    //     result = result * 0x100000000000B17217F7D1D351A389D40 >> 64;
    //   if (x & 0x80000 > 0)
    //     result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 64;
    //   if (x & 0x40000 > 0)
    //     result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 64;
    //   if (x & 0x20000 > 0)
    //     result = result * 0x100000000000162E42FEFA39FE95583C2 >> 64;
    //   if (x & 0x10000 > 0)
    //     result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 64;
    //   if (x & 0x8000 > 0)
    //     result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 64;
    //   if (x & 0x4000 > 0)
    //     result = result * 0x10000000000002C5C85FDF473E242EA38 >> 64;
    //   if (x & 0x2000 > 0)
    //     result = result * 0x1000000000000162E42FEFA39F02B772C >> 64;
    //   if (x & 0x1000 > 0)
    //     result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 64;
    //   if (x & 0x800 > 0)
    //     result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 64;
    //   if (x & 0x400 > 0)
    //     result = result * 0x100000000000002C5C85FDF473DEA871F >> 64;
    //   if (x & 0x200 > 0)
    //     result = result * 0x10000000000000162E42FEFA39EF44D91 >> 64;
    //   if (x & 0x100 > 0)
    //     result = result * 0x100000000000000B17217F7D1CF79E949 >> 64;
    //   if (x & 0x80 > 0)
    //     result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 64;
    //   if (x & 0x40 > 0)
    //     result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 64;
    //   if (x & 0x20 > 0)
    //     result = result * 0x100000000000000162E42FEFA39EF366F >> 64;
    //   if (x & 0x10 > 0)
    //     result = result * 0x1000000000000000B17217F7D1CF79AFA >> 64;
    //   if (x & 0x8 > 0)
    //     result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 64;
    //   if (x & 0x4 > 0)
    //     result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 64;
    //   if (x & 0x2 > 0)
    //     result = result * 0x1000000000000000162E42FEFA39EF358 >> 64;
    //   if (x & 0x1 > 0)
    //     result = result * 0x10000000000000000B17217F7D1CF79AB >> 64;

       //result >>= uint256 (int256 (63 - (x >> 64)));
      result = ((63 - (x >> 64)) as u128);
      
      //require (result <= uint256 (int256 (MAX_64x64)));
      assert!(result <= 0x7FFFFFFFFFFFFFFF, 0);
     // return int128 (int256 (result));
      return (result as u64)
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 32.32-bit fixed point number
   * @return signed 32.32-bit fixed point number
   */
    public fun exp(a: FixedPoint32): FixedPoint32 {
        let x = (i64::as_raw_bits(&a.value) as u128);
        assert!(x < 0x7FFFFFFFFFFFFFFF, 0);
        let c = (i64::as_u64(&i64::abs(&a.value)) as u64);
        let something = exp_2(c);
        debug::print(&something);
        FixedPoint32{value: i64::from((something as u64) >> 64)}

       // return exp_2 ( int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
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
