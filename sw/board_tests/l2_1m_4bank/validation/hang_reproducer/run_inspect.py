from pathlib import Path
import os,subprocess,time
root=Path(__file__).resolve().parents[2]
folder=Path(__file__).resolve().parent
config=root/'program/openocd/openocd-bscan.cfg'
env=dict(os.environ,BOARD_JTAG_SERIAL='210357A7D00E')
with (folder/'openocd.log').open('w') as output:
    server=subprocess.Popen(['/home/wzr/riscv-openocd/src/openocd','-f',str(config)],env=env,stdout=output,stderr=subprocess.STDOUT)
    try:
        for i in range(100):
            text=(folder/'openocd.log').read_text()
            if 'Listening on port 3333 for gdb connections' in text and 'Target successfully examined' in text:
                break
            if server.poll() is not None:
                raise RuntimeError('OpenOCD exited: '+text)
            time.sleep(0.1)
        else:
            raise RuntimeError('OpenOCD startup timeout: '+text)
        env['PYTHONHOME']='/home/wzr/chipyard/.conda-env'
        cmd=['/home/wzr/chipyard/.conda-env/riscv-tools/bin/riscv64-unknown-elf-gdb','-q','-batch',str(root/'build/yolov5_reference.elf'),'-x',str(folder/'inspect.py')]
        with (folder/'gdb.log').open('w') as out:
            done=subprocess.run(cmd,env=env,stdout=out,stderr=subprocess.STDOUT,timeout=50)
        print((folder/'gdb.log').read_text(),flush=True)
        raise SystemExit(done.returncode)
    finally:
        server.terminate()
        try:server.wait(timeout=5)
        except subprocess.TimeoutExpired:server.kill();server.wait()
