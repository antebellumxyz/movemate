

module movemate::deque {

    //Indexed sequence container
    // fast insertion and deletion at beginning and its end.


    struct Deque has store {
        size: u64,
        type: T,

    }

    // adds element to the end
    public fun push_back(deque: Deque, value: u128) {

    }

    // adds element to the front
    public fun push_front(deque: Deque, value: u128) {

    }

    // removes last element 
    public fun pop_back(deque: Deque, value: u128) {

    }

    // removes first element 
    public fun pop_front(deque: Deque, value: u128) {

    }

    // access to element at index
    public fun at(deque: Deque, index: u128): u128 {

    }

    // access to front element
    public fun front(deque: Deque): u128 {

    }

    // access to back element
    public fun back(deque: Deque): u128 {
        
    }

    // checks if queue is empty
    public fun empty(deque: Deque): bool {

    }

    // returns number of elemnts in queue
    public fun size(deque: Deque): u128 {

    }
    
    
}