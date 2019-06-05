ENTRY(startup_32) 

SECTIONS
{
    .text :
    {
        *(.text)
    }
    .data : ALIGN(8B)
    {
        *(.data)
    }
}