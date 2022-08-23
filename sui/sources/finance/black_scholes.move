module movemate::black_scholes {
    use movemate::fixed_point64::{Self, FixedPoint64};
    use std::debug;

    // https://cseweb.ucsd.edu/~goguen/courses/130/SayBlackScholes.html

    public fun CND(x: &FixedPoint64): FixedPoint64 {
        //let a1: FixedPoint64 = fixed_point64::create_from_rational(31938153, 100000000);
        // this should be negative but we don't have signed FixedPoint64s yet. 
        // let a2: FixedPoint64 = fixed_point64::create_from_rational(356563782, 100000000);
        // let a3: FixedPoint64 = fixed_point64::create_from_rational(1781477937, 100000000);
        // let a4: FixedPoint64 = fixed_point64::create_from_rational(1821255978, 100000000);
        // let a5: FixedPoint64 = fixed_point64::create_from_rational(1330274429, 100000000);
    
        //let pi: FixedPoint64 = fixed_point64::create_from_rational(314159265358, 100000000000);

        //debug::print(&pi);

        let k: FixedPoint64 = fixed_point64::divide(
            fixed_point64::create_from_rational(1, 1),
            fixed_point64::add(
                fixed_point64::add(
                    fixed_point64::create_from_rational(1, 1), 
                    fixed_point64::create_from_rational(2316419, 100000000)
                ),
                *x 
            )
        );
        debug::print(&k);
        // w = 1.0 - 1.0 / sqrt(2 * Pi) * exp(-L *L / 2) * (a1 * K + a2 * K *K + a3 * pow(K,3) + a4 * pow(K,4) + a5 * pow(K,5));

        k
    }

    #[test]
    fun test_cnd() {
        let a = fixed_point64::create_from_rational(10, 25);
        //debug::print(&a);
        CND(&a);
    }
}