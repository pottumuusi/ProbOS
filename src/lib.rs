// #![feature(panic_implementation)]
#![feature(lang_items)]
#![feature(const_fn)]
#![feature(ptr_internals)]
#![no_std]

extern crate rlibc;
extern crate volatile;
extern crate spin;

#[macro_use]
mod vga_buffer;

use core::panic::PanicInfo;

#[no_mangle]
pub extern fn rust_main() {
    // NOTE: Stack is small and there is no guard page

    vga_buffer::clear_screen();
    println!("Hello World{}", "!");

    // Print with possibility for deadlocking.
    println!("{}", { println!("inner"); "outer" });

    loop{}
}

#[lang = "eh_personality"] #[no_mangle] pub extern fn eh_personality() {}
#[panic_handler] #[no_mangle] pub fn panic(_info: &PanicInfo) -> ! {
    // TODO use PanicInfo here
    let buffer_ptr = (0xb8000) as *mut _;
    let red = 0x4f;
    unsafe {
        *buffer_ptr = [b'P', red, b'a', red, b'n', red, b'i', red, b'c', red, b'!', red];
    };
    loop{}
}
