/*
 * getdata.c
 * A very simple BoF (buffer overflow) example
 *
 * Part of my 'hacksec' github repo:
 * https://github.com/kaiwan/hacksec
 *
 * Kaiwan N Billimoria
 * kaiwanTECH (Designer Graphix)
 */
static void foo(void)
{
     char local[128];
     printf("Name: ");
     gets(local);
}

void main() {
    foo();
    printf("Ok, about to exit...\n");
}
