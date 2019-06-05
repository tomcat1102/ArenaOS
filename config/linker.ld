ENTRY(startup_32) 

SECTIONS
{
    .text :
    {
        *(.text)
    }
    .data :
    {
        *(.data)
    }
}