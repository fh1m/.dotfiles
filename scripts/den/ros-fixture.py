#!/usr/bin/env python3
"""Finite ROS 2 peer fixture. Run explicitly inside a sourced ROS environment."""
import argparse
import hashlib
import json
import re
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('role', choices=['publish', 'receive'])
    parser.add_argument('--nonce', required=True)
    parser.add_argument('--seconds', type=int, default=30)
    args = parser.parse_args()
    if not re.fullmatch(r'[A-Za-z0-9_-]{1,64}', args.nonce) or not 1 <= args.seconds <= 60:
        parser.error('Use a simple nonce and a duration between 1 and 60 seconds')
    import rclpy
    from std_msgs.msg import String
    rclpy.init()
    node = rclpy.create_node('den_fixture_' + args.role)
    topic = '/den_fixture/' + args.nonce
    payload = json.dumps({'protocol': 1, 'nonce': args.nonce}, sort_keys=True)
    digest = hashlib.sha256(payload.encode()).hexdigest()
    received = []
    if args.role == 'publish':
        publisher = node.create_publisher(String, topic, 10)
        def publish():
            message = String();message.data = payload;publisher.publish(message)
        timer = node.create_timer(0.25, publish)
    else:
        def receive(message):
            if message.data == payload:received.append(message.data)
        subscription = node.create_subscription(String, topic, receive, 10)
    deadline = time.monotonic() + args.seconds
    try:
        while time.monotonic() < deadline and not received:
            rclpy.spin_once(node, timeout_sec=0.25)
        if args.role == 'receive' and not received:
            print(json.dumps({'received': False, 'reason': 'No matching peer payload before timeout'}))
            return 1
        print(json.dumps({'role': args.role, 'sha256': digest, 'received': bool(received)}))
        return 0
    finally:
        node.destroy_node();rclpy.shutdown()


if __name__ == '__main__':
    raise SystemExit(main())
