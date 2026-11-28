import runpy
from pathlib import Path


HELPER = Path(__file__).resolve().parents[1] / 'home/.local/bin/sensei-ethernet'


def test_usb_gadget_does_not_count_as_cabled_lan(tmp_path):
    net = tmp_path / 'class' / 'net'
    net.mkdir(parents=True)
    gadget = tmp_path / 'devices' / 'jetson'
    adapter = tmp_path / 'devices' / 'usb-lan'
    for device, vendor, product in ((gadget, '0955', '7020'), (adapter, '0bda', '8152')):
        device.mkdir(parents=True)
        (device / 'idVendor').write_text(vendor)
        (device / 'idProduct').write_text(product)

    def interface(name, device, index, carrier):
        function = device / index
        function.mkdir()
        link = net / name
        link.mkdir()
        (link / 'device').symlink_to(function, target_is_directory=True)
        (link / 'type').write_text('1')
        (link / 'carrier').write_text(carrier)
        return link

    interface('jetson-rndis', gadget, '1-13:1.0', '1')
    interface('jetson-ncm', gadget, '1-13:1.5', '1')
    lan = interface('usb-lan', adapter, '1-15:1.0', '0')
    wired = runpy.run_path(str(HELPER))['wired_carriers']
    assert wired(net) == []
    (lan / 'carrier').write_text('1')
    assert wired(net) == [{'name': 'usb-lan'}]
    (lan / 'carrier').write_text('0')
    assert wired(net) == []
