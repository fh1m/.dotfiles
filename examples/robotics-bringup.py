#!/usr/bin/env python3
"""ROS 2: publish an annotated robot heartbeat at 20 Hz."""
import rclpy
from rclpy.node import Node
from std_msgs.msg import String

class RobotHeartbeat(Node):
    def __init__(self):
        super().__init__('sensei_heartbeat')
        self.publisher = self.create_publisher(String, '/robot/status', 10)
        self.timer = self.create_timer(0.05, self.publish_status)
        self.sequence = 0

    def publish_status(self):
        self.sequence += 1
        message = String()
        message.data = f'robot online • heartbeat {self.sequence}'
        self.publisher.publish(message)

def main():
    rclpy.init()
    node = RobotHeartbeat()
    try:
        rclpy.spin(node)
    finally:
        node.destroy_node()
        rclpy.shutdown()

if __name__ == '__main__':
    main()
