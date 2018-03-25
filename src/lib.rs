#![feature(lang_items)]
#![feature(const_fn)]
#![feature(ptr_internals)]
#![no_std]

extern crate rlibc;
extern crate volatile;

mod vga_buffer;

#[no_mangle]
pub extern fn rust_main() {
    // NOTE: Stack is small and there is no guard page

    let hello = b"Hello World!";
    let color_byte = 0x1f; // White foreground, blue background

    let mut hello_colored = [color_byte; 24];
    for (i, char_byte) in hello.into_iter().enumerate() {
        hello_colored[i*2] = *char_byte;
    }

    // Write "Hello World!" to the center of the VGA text buffer
    let buffer_ptr = (0xb8000 + 1988) as *mut _;
    unsafe { *buffer_ptr = hello_colored };

    vga_buffer::print_something();

    loop{}
}

#[lang = "eh_personality"] #[no_mangle] pub extern fn eh_personality() {}
#[lang = "panic_fmt"] #[no_mangle] pub extern fn panic_fmt() -> ! {
    let buffer_ptr = (0xb8000) as *mut _;
    let red = 0x4f;
    unsafe {
        *buffer_ptr = [b'P', red, b'a', red, b'n', red, b'i', red, b'c', red, b'!', red];
    };
    loop{}
}
