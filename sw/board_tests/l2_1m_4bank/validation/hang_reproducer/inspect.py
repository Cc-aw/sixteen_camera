import gdb,time

def run(command):
    print('PROBE_COMMAND='+command)
    try:
        gdb.execute(command)
    except gdb.error as error:
        print('PROBE_ERROR='+str(error))
run('set pagination off')
run('set confirm off')
run('set remotetimeout 15')
run('target extended-remote localhost:3333')
try:
    for sample in range(2):
        print('PROBE_SAMPLE='+str(sample))
        run('monitor halt')
        for command in ['info registers pc ra sp mstatus mie mepc mcause mtval',
                        'x/12i $pc-12','info line *$pc','bt','p executor','p current_frame',
                        'p current_lane','p current_phase','p planning','p recording',
                        'p next_frame','p completed','p irq_count']:
            run(command)
        if sample==0:
            run('monitor resume')
            time.sleep(1)
finally:
    run('monitor resume')
    run('disconnect')
