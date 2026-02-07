import os
import re
import sys
import time
import shutil
import random
import string
import subprocess
import ctypes
import threading
from dataclasses import dataclass
from typing import List, Optional, Dict

from zeroconf import IPVersion, ServiceBrowser, ServiceStateChange, Zeroconf


MDNS_LINE_RE = re.compile(
    r"^(?P<name>\S+)\s+(?P<type>_adb-tls-(?:connect|pairing)\._tcp\.?)\s+(?P<ip>\d+\.\d+\.\d+\.\d+):(?P<port>\d+)\s*$"
)

@dataclass
class MdnsService:
    name: str
    type: str
    ip: str
    port: int


@dataclass
class DeviceState:
    pair_service: Optional[MdnsService] = None
    connect_service: Optional[MdnsService] = None
    paired: bool = False
    connected: bool = False
    error: Optional[str] = None


def tool_path(name: str) -> Optional[str]:
    return shutil.which(name)


def run(cmd: List[str], *, env=None, capture=True, input_text: Optional[str] = None) -> subprocess.CompletedProcess:
    return subprocess.run(
        cmd,
        env=env,
        text=True,
        capture_output=capture,
        input=input_text,
        check=False,
    )


def is_admin() -> bool:
    try:
        return bool(ctypes.windll.shell32.IsUserAnAdmin())
    except Exception:
        return False


def adb_env() -> dict:
    env = os.environ.copy()
    env["ADB_MDNS_OPENSCREEN"] = "1"
    return env


def restart_adb(env: dict) -> None:
    run(["adb", "kill-server"], env=env, capture=True)
    run(["adb", "start-server"], env=env, capture=True)


def parse_adb_devices_allow_spaces(output: str) -> List[str]:
    serials: List[str] = []
    for ln in output.splitlines():
        ln = ln.strip()
        if not ln or ln.lower().startswith("list of devices"):
            continue
        parts = ln.rsplit(None, 1)
        if len(parts) != 2:
            continue
        serial, state = parts[0], parts[1]
        if state == "device":
            serials.append(serial)
    return serials


def get_connected_device_serial(env: dict) -> Optional[str]:
    cp = run(["adb", "devices"], env=env, capture=True)
    serials = parse_adb_devices_allow_spaces(cp.stdout or "")
    if not serials:
        return None
    wifi = [s for s in serials if re.search(r"\d+\.\d+\.\d+\.\d+:\d+", s)]
    return wifi[0] if wifi else serials[0]


def parse_mdns_services(output: str) -> List[MdnsService]:
    services: List[MdnsService] = []
    for ln in output.splitlines():
        ln = ln.strip()
        m = MDNS_LINE_RE.match(ln)
        if not m:
            continue
        services.append(
            MdnsService(
                name=m.group("name"),
                type=m.group("type"),
                ip=m.group("ip"),
                port=int(m.group("port")),
            )
        )
    return services


def print_qr(payload: str) -> None:
    import qrcode
    qr = qrcode.QRCode(border=1)
    qr.add_data(payload)
    qr.make(fit=True)
    print()
    qr.print_ascii(invert=True)
    print()


def adb_pair(env: dict, ip: str, port: int, password: str) -> bool:
    addr = f"{ip}:{port}"
    cp = run(["adb", "pair", addr, password], env=env, capture=True)
    print(cp.stdout or "", end="")
    out = (cp.stdout or "").lower() + (cp.stderr or "").lower()
    if cp.returncode != 0 or "success" not in out:
        print(cp.stderr or "", end="")
        return False
    return True


def adb_connect(env: dict, ip: str, port: int) -> bool:
    addr = f"{ip}:{port}"
    cp = run(["adb", "connect", addr], env=env, capture=True)
    print(cp.stdout or "", end="")
    out = (cp.stdout or "").lower() + (cp.stderr or "").lower()
    if cp.returncode != 0 or "refused" in out or "failed" in out:
        print(cp.stderr or "", end="")
        return False
    return True


def flutter_run(device_serial: str, extra_flutter_args: List[str]) -> int:
    args = ["flutter", "run", "-d", device_serial] + extra_flutter_args
    print("\nRunning:", " ".join(args), "\n")
    if os.name == "nt":
        return subprocess.call([os.environ.get("COMSPEC", "cmd.exe"), "/c"] + args)
    return subprocess.call(args)


def windows_allow_mdns_firewall(adb_exe: str) -> None:
    run(["netsh", "advfirewall", "firewall", "set", "rule", 'group="Network Discovery"', "new", "enable=Yes"], capture=True)

    ps = f"""
$adb = '{adb_exe.replace("'", "''")}'
$python = '{sys.executable.replace("'", "''")}'
$rules = @(
  @{{Name='ADB mDNS UDP 5353 (Private)'; Proto='UDP'; Port=5353; Path=$adb}},
  @{{Name='ADB TCP inbound (Private)';     Proto='TCP'; Port='Any'; Path=$adb}},
  @{{Name='Python mDNS UDP 5353 (Private)'; Proto='UDP'; Port=5353; Path=$python}},
  @{{Name='Python TCP inbound (Private)';     Proto='TCP'; Port='Any'; Path=$python}}
)
foreach ($r in $rules) {{
  $exists = Get-NetFirewallRule -DisplayName $r.Name -ErrorAction SilentlyContinue
  if (-not $exists) {{
    if ($r.Port -eq 'Any') {{
      New-NetFirewallRule -DisplayName $r.Name -Direction Inbound -Program $r.Path -Action Allow -Protocol $r.Proto -Profile Private | Out-Null
    }} else {{
      New-NetFirewallRule -DisplayName $r.Name -Direction Inbound -Program $r.Path -Action Allow -Protocol $r.Proto -LocalPort $r.Port -Profile Private | Out-Null
    }}
  }}
}}
"""
    run(["powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", ps], capture=True)


def main() -> int:
    adb_exe = tool_path("adb")
    if not adb_exe:
        print("[!] adb not found in PATH.")
        return 2
    if not tool_path("flutter"):
        print("[!] flutter not found in PATH.")
        return 2

    extra_flutter_args = sys.argv[1:]
    env = adb_env()

    restart_adb(env)

    serial = get_connected_device_serial(env)
    if serial:
        return flutter_run(serial, extra_flutter_args)

    print("No device connected.")
    print("Preparing mDNS for QR pairing (Windows fixes + adb restart)...\n")

    if is_admin():
        windows_allow_mdns_firewall(adb_exe)
        print("[OK] Firewall/Network Discovery rules applied (Admin).")
    else:
        print("[!] Not running as Admin. Skipping firewall rule changes.")
        print("[!] Run as Admin to enable mDNS firewall rules for reliable pairing.\n")

    restart_adb(env)

    name = "".join(random.choices(string.ascii_letters + string.digits, k=8))
    password = "".join(random.choices(string.ascii_letters + string.digits, k=8))
    qr_payload = f"WIFI:T:ADB;S:{name};P:{password};;"

    print("Open on phone: Developer options → Wireless debugging → Pair device with QR code")
    print("Then scan this QR from your phone:\n")
    print_qr(qr_payload)

    devices: Dict[str, DeviceState] = {}
    event = threading.Event()

    def on_service_change(
        zeroconf: Zeroconf,
        service_type: str,
        name: str,
        state_change: ServiceStateChange,
    ) -> None:
        if state_change != ServiceStateChange.Added:
            return

        try:
            info = zeroconf.get_service_info(service_type, name)
            if not info:
                return

            addresses = info.parsed_addresses()
            if not addresses:
                return

            ip = addresses[0]
            port = info.port

            if ip not in devices:
                devices[ip] = DeviceState()

            if service_type == "_adb-tls-pairing._tcp.local.":
                devices[ip].pair_service = MdnsService(name=name, type=service_type, ip=ip, port=port)
                print(f"[i] Found pairing service: {ip}:{port}")

                if devices[ip].connect_service and not devices[ip].paired:
                    print(f"[i] Both services found for {ip}, attempting to pair...")
                    if adb_pair(env, ip, port, password):
                        devices[ip].paired = True
                        conn_port = devices[ip].connect_service.port
                        print(f"[i] Pairing successful, connecting to {ip}:{conn_port}...")
                        if adb_connect(env, ip, conn_port):
                            devices[ip].connected = True
                            event.set()
                        else:
                            devices[ip].error = "Connect failed"
                    else:
                        devices[ip].error = "Pair failed"

            elif service_type == "_adb-tls-connect._tcp.local.":
                devices[ip].connect_service = MdnsService(name=name, type=service_type, ip=ip, port=port)
                print(f"[i] Found connect service: {ip}:{port}")

                if devices[ip].pair_service and not devices[ip].paired:
                    pair_port = devices[ip].pair_service.port
                    print(f"[i] Both services found for {ip}, attempting to pair...")
                    if adb_pair(env, ip, pair_port, password):
                        devices[ip].paired = True
                        print(f"[i] Pairing successful, connecting to {ip}:{port}...")
                        if adb_connect(env, ip, port):
                            devices[ip].connected = True
                            event.set()
                        else:
                            devices[ip].error = "Connect failed"
                    else:
                        devices[ip].error = "Pair failed"

        except Exception as e:
            print(f"[!] Error in service change handler: {e}")

    zc = Zeroconf(ip_version=IPVersion.V4Only)

    ServiceBrowser(
        zc=zc,
        type_=["_adb-tls-pairing._tcp.local.", "_adb-tls-connect._tcp.local."],
        handlers=[on_service_change],
    )

    print("[i] Waiting for device to pair (timeout 60s)...")
    if event.wait(timeout=60):
        for ip, state in devices.items():
            if state.connected:
                zc.close()
                for _ in range(10):
                    serial = get_connected_device_serial(env)
                    if serial:
                        return flutter_run(serial, extra_flutter_args)
                    time.sleep(1)
                print("\n[!] Paired but no device appears in `adb devices`.")
                return 5

        for ip, state in devices.items():
            if state.error:
                print(f"[!] {state.error}")
        return 4
    else:
        print("\n[!] Timeout waiting for device. Ensure:")
        print("    - Phone and PC are on same network")
        print("    - Network allows mDNS (no guest Wi-Fi, router supports mDNS)")
        print("    - Firewall allows mDNS (run as Admin or enable Network Discovery)")
        zc.close()
        return 4


if __name__ == "__main__":
    raise SystemExit(main())
