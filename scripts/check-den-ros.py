#!/usr/bin/env python3
"""Explicit live ROS 2 round trip between Arete's container and Homie.

Requires the reviewed peer firewall rules for domain 83 and cached Humble image.
Only owned String topics and temporary files/containers are created.
"""
from pathlib import Path
import argparse,socket,ipaddress,os
import subprocess,json,uuid,shlex,time
parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--live',action='store_true');args=parser.parse_args()
if not args.live:parser.error('This test controls owned ROS nodes on both hosts; pass --live explicitly')
if socket.gethostname().split('.')[0]!='arete':parser.error('Run on Arete')
peer=str(ipaddress.IPv4Address(json.loads((Path.home()/'.config/sensei-den/access.json').read_text())['lanAddress']))
with socket.socket(socket.AF_INET,socket.SOCK_DGRAM) as route:
 route.connect((peer,9));local=route.getsockname()[0]
r=Path.home()/'.local/state/homie-control';ssh=['ssh','-F',str(r/'client.conf'),'homie'];ident=uuid.uuid4().hex[:10];topic='/den_acceptance_'+ident;name='den-ros-'+ident
xml=lambda address:f'''<?xml version="1.0" encoding="UTF-8"?><profiles xmlns="http://www.eprosima.com/XMLSchemas/fastRTPS_Profiles"><transport_descriptors><transport_descriptor><transport_id>den_udp</transport_id><type>UDPv4</type><interfaceWhiteList><address>{address}</address></interfaceWhiteList></transport_descriptor></transport_descriptors><participant profile_name="den" is_default_profile="true"><rtps><defaultUnicastLocatorList><locator><udpv4><address>{address}</address><port>28161</port></udpv4></locator></defaultUnicastLocatorList><builtin><metatrafficUnicastLocatorList><locator><udpv4><address>{address}</address><port>28160</port></udpv4></locator></metatrafficUnicastLocatorList><initialPeersList><locator><udpv4><address>{peer if address==local else local}</address><port>28160</port></udpv4></locator></initialPeersList></builtin><userTransports><transport_id>den_udp</transport_id></userTransports><useBuiltinTransports>false</useBuiltinTransports></rtps></participant></profiles>'''
localxml='/tmp/'+name+'.xml';pcxml='/tmp/'+name+'.xml'
subprocess.run(['docker','exec','-i','auv-ros2','sh','-c','cat >'+localxml],input=xml(local).encode(),check=True)
subprocess.run(ssh+['cat >'+shlex.quote(pcxml)],input=xml(peer).encode(),check=True)
subscriber=f'''import rclpy,time,json,sys
from std_msgs.msg import String
rclpy.init();n=rclpy.create_node('den_sub_{ident}');seen=[]
ack=n.create_publisher(String,{(topic+'_ack')!r},10)
def receive(msg):
 seen.append(msg.data);reply=String();reply.data=msg.data;ack.publish(reply)
s=n.create_subscription(String,{topic!r},receive,10)
end=time.monotonic()+35
while not seen and time.monotonic()<end:rclpy.spin_once(n,timeout_sec=.2)
print(json.dumps({{'received':bool(seen) and all(x=={ident!r} for x in seen),'domain':83,'direction':'Arete to Homie'}}),flush=True)
end=time.monotonic()+1
while time.monotonic()<end:rclpy.spin_once(n,timeout_sec=.1)
n.destroy_node();rclpy.shutdown();sys.exit(0 if bool(seen) and all(x=={ident!r} for x in seen) else 1)
'''
publisher=f'''import rclpy,time
from std_msgs.msg import String
rclpy.init();n=rclpy.create_node('den_pub_{ident}');p=n.create_publisher(String,{topic!r},10)
seen=[];n.create_subscription(String,{(topic+'_ack')!r},lambda msg:seen.append(msg.data),10)
end=time.monotonic()+15
while time.monotonic()<end and not seen:
 rclpy.spin_once(n,timeout_sec=.1);m=String();m.data={ident!r};p.publish(m)
print('ACK_VERIFIED' if bool(seen) and all(x=={ident!r} for x in seen) else 'ACK_MISSING',flush=True)
n.destroy_node();rclpy.shutdown();raise SystemExit(0 if bool(seen) and all(x=={ident!r} for x in seen) else 1)
'''
command=['docker','run','--rm','--name',name,'--network','host','-e','ROS_DOMAIN_ID=83','-e','ROS_LOCALHOST_ONLY=0','-e','RMW_IMPLEMENTATION=rmw_fastrtps_cpp','-e','FASTRTPS_DEFAULT_PROFILES_FILE=/tmp/den.xml','-v',pcxml+':/tmp/den.xml:ro','-i','osrf/ros:humble-desktop','bash','-c','source /opt/ros/humble/setup.bash; python3 -']
receiver=subprocess.Popen(ssh+[shlex.join(command)],stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
receiver.stdin.write(subscriber);receiver.stdin.close()
try:
 time.sleep(3)
 cmd=['docker','exec','-i','-e','ROS_DOMAIN_ID=83','-e','ROS_LOCALHOST_ONLY=0','-e','RMW_IMPLEMENTATION=rmw_fastrtps_cpp','-e','FASTRTPS_DEFAULT_PROFILES_FILE='+localxml,'auv-ros2','bash','-c','source /opt/ros/humble/setup.bash; python3 -']
 pub=subprocess.run(cmd,input=publisher,capture_output=True,text=True,timeout=25);code=receiver.wait(timeout=45);out=receiver.stdout.read();err=receiver.stderr.read()
 result={'publisherExit':pub.returncode,'subscriberExit':code,'messageVerified':ident in out or '"received": true' in out,'returnAckVerified':'ACK_VERIFIED' in pub.stdout,'domain':83,'scope':'owned String topic over isolated wired DDS transport; no robot nodes or actuators'}
 (r/'ros-acceptance.json').write_text(json.dumps(result,indent=2));(r/'ros-acceptance-private.log').write_text(out+err+pub.stderr)
 print(json.dumps(result))
 if pub.returncode or code:raise SystemExit(1)
finally:
 subprocess.run(ssh+['docker rm -f '+shlex.quote(name)],capture_output=True)
 subprocess.run(ssh+['rm -f '+shlex.quote(pcxml)],capture_output=True)
 subprocess.run(['docker','exec','auv-ros2','rm','-f',localxml],capture_output=True)
