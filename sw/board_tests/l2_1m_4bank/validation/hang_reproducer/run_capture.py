from pathlib import Path
import os,select,subprocess,sys,termios,time
root=Path(__file__).resolve().parents[2]
folder=Path(__file__).resolve().parent
elf=Path(sys.argv[1]).resolve();label=sys.argv[2];duration=float(sys.argv[3])
fd=os.open('/dev/ttyACM0',os.O_RDWR|os.O_NOCTTY|os.O_NONBLOCK)
attrs=termios.tcgetattr(fd)
attrs[0]=0;attrs[1]=0;attrs[2]=termios.CS8|termios.CREAD|termios.CLOCAL;attrs[3]=0
attrs[4]=attrs[5]=termios.B115200
attrs[6][termios.VMIN]=0;attrs[6][termios.VTIME]=0
termios.tcsetattr(fd,termios.TCSANOW,attrs);termios.tcflush(fd,termios.TCIFLUSH)
env=dict(os.environ,BOARD_JTAG_SERIAL='210357A7D00E',
    OPENOCD_BIN='/home/wzr/riscv-openocd/src/openocd',
    GDB_BIN='/home/wzr/chipyard/.conda-env/riscv-tools/bin/riscv64-unknown-elf-gdb',
    GDB_PYTHONHOME='/home/wzr/chipyard/.conda-env',
    ELF_FILE=str(elf),OPENOCD_LOG=str(folder/(label+'.openocd.log')))
with (folder/(label+'.download.log')).open('w') as download, (folder/(label+'.uart.log')).open('wb') as uart:
    process=subprocess.Popen(['bash',str(root/'program/run_firmware.sh'),'--no-build'],env=env,stdout=download,stderr=subprocess.STDOUT)
    deadline=time.monotonic()+max(120,duration)
    download_finished=False
    try:
        while time.monotonic()<deadline:
            ready,_,_=select.select([fd],[],[],0.2)
            if ready:
                data=os.read(fd,65536)
                if data:
                    uart.write(data);uart.flush();print(data.decode(errors='replace'),end='',flush=True)
            status=process.poll()
            if status == 0 and not download_finished:
                download_finished=True;deadline=time.monotonic()+duration
            if status is not None and status:
                print('DOWNLOAD_FAILED='+str(status),flush=True);break
        if process.poll() is None:
            process.terminate();process.wait(timeout=5)
        print('\nCAPTURE_END download_exit='+str(process.returncode),flush=True)
    finally:
        os.close(fd)
