/* Compile this translation unit without V. IRQ may arrive during any RVV
 * kernel: leave vl/vtype/vstart/vector registers untouched. No model kernel,
 * memory helper or command query is called on the normal interrupt path. */
#include <stdint.h>
extern volatile unsigned irq_event;
extern volatile uint64_t irq_count,irq_cycles;
volatile uint64_t irq_first_cycle;
extern volatile unsigned memory_probe_active,memory_probe_failed;
extern void at_irq_fault(uint64_t cause,uint64_t pc,uint64_t val) __attribute__((noreturn));
void __attribute__((interrupt("machine"),aligned(4))) trap_entry(void) {
    uint64_t begin,end,cause,pc,val;
    __asm__ volatile("rdcycle %0":"=r"(begin));
    __asm__ volatile("csrr %0,mcause":"=r"(cause));
    if(cause==5&&memory_probe_active) {
        __asm__ volatile("csrr %0,mepc":"=r"(pc));
        __asm__ volatile("csrr %0,mtval":"=r"(val));
        if(val>=UINT64_C(0x02020000)&&val<UINT64_C(0x02020008)) {
            memory_probe_failed=1;memory_probe_active=0;
            __asm__ volatile("csrw mepc,%0"::"r"(pc+4):"memory");
            return;
        }
    }
    if(cause!=((UINT64_C(1)<<63)|13)) {
        __asm__ volatile("csrr %0,mepc":"=r"(pc));
        __asm__ volatile("csrr %0,mtval":"=r"(val));
        at_irq_fault(cause,pc,val);
    }
    __asm__ volatile("csrc mie,%0"::"r"(1ul<<13):"memory");
    if(!irq_event)irq_first_cycle=begin;
    irq_event=1;irq_count++;
    __asm__ volatile("rdcycle %0":"=r"(end));irq_cycles+=end-begin;
}
