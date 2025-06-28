#!/usr/bin/env python3
"""
WebSocket client test script for testing Vision Pro hand tracking data transmission.
"""

import asyncio
import websockets
import json
import time
import random
import argparse
import logging
from datetime import datetime

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class HandTrackingClient:
    def __init__(self, server_url):
        self.server_url = server_url
        self.message_count = 0
        self.connected = False
        
    async def generate_mock_hand_data(self, is_left=True):
        """Generate mock hand tracking data similar to Vision Pro format"""
        joints = []
        base_x = -0.1 if is_left else 0.1
        
        # Generate 27 joint positions with some random movement
        for i in range(27):
            x = base_x + random.uniform(-0.02, 0.02)
            y = 0.5 + (i * 0.01) + random.uniform(-0.01, 0.01)
            z = -0.3 + random.uniform(-0.02, 0.02)
            joints.append([x, y, z])
        
        # Create tracked mask (all joints tracked in this test)
        tracked_mask = (1 << 27) - 1
        
        return {
            "joints": joints,
            "trackedMask": tracked_mask
        }
    
    async def send_single_hand_message(self, websocket, is_left=True):
        """Send a single hand tracking message"""
        joints = []
        for i in range(27):
            joint = {
                "name": f"joint_{i}",
                "position": [
                    random.uniform(-0.5, 0.5),
                    random.uniform(0, 1),
                    random.uniform(-1, 0)
                ],
                "isTracked": True
            }
            joints.append(joint)
        
        message = {
            "timestamp": time.time(),
            "isLeft": is_left,
            "joints": joints
        }
        
        await websocket.send(json.dumps(message))
        self.message_count += 1
        logger.info(f"Sent single hand message #{self.message_count} ({'left' if is_left else 'right'} hand)")
    
    async def send_both_hands_message(self, websocket):
        """Send both hands tracking data in compact format"""
        left_hand = await self.generate_mock_hand_data(is_left=True)
        right_hand = await self.generate_mock_hand_data(is_left=False)
        
        message = {
            "timestamp": time.time(),
            "leftHand": left_hand,
            "rightHand": right_hand
        }
        
        await websocket.send(json.dumps(message))
        self.message_count += 1
        logger.info(f"Sent both hands message #{self.message_count}")
    
    async def receive_messages(self, websocket):
        """Receive and log server responses"""
        try:
            while self.connected:
                message = await asyncio.wait_for(websocket.recv(), timeout=0.1)
                data = json.loads(message)
                logger.info(f"Received: {data}")
        except asyncio.TimeoutError:
            pass
        except Exception as e:
            if self.connected:
                logger.error(f"Receive error: {e}")
    
    async def run_test(self, test_mode="both", duration=10, rate=30):
        """Run the WebSocket client test"""
        try:
            async with websockets.connect(self.server_url) as websocket:
                self.connected = True
                logger.info(f"Connected to {self.server_url}")
                
                # Start receiving messages in background
                receive_task = asyncio.create_task(self.receive_messages(websocket))
                
                # Send messages at specified rate
                interval = 1.0 / rate
                start_time = time.time()
                
                while time.time() - start_time < duration:
                    send_start = time.time()
                    
                    if test_mode == "both":
                        await self.send_both_hands_message(websocket)
                    elif test_mode == "left":
                        await self.send_single_hand_message(websocket, is_left=True)
                    elif test_mode == "right":
                        await self.send_single_hand_message(websocket, is_left=False)
                    elif test_mode == "alternate":
                        is_left = self.message_count % 2 == 0
                        await self.send_single_hand_message(websocket, is_left=is_left)
                    
                    # Wait for next interval
                    elapsed = time.time() - send_start
                    if elapsed < interval:
                        await asyncio.sleep(interval - elapsed)
                
                self.connected = False
                await receive_task
                
                logger.info(f"Test completed. Sent {self.message_count} messages in {duration} seconds")
                logger.info(f"Average rate: {self.message_count / duration:.1f} messages/second")
                
        except websockets.exceptions.WebSocketException as e:
            logger.error(f"WebSocket error: {e}")
        except Exception as e:
            logger.error(f"Error: {e}")
            raise

async def stress_test(server_url, num_clients=5, duration=10):
    """Run multiple clients simultaneously for stress testing"""
    logger.info(f"Starting stress test with {num_clients} clients")
    
    tasks = []
    for i in range(num_clients):
        client = HandTrackingClient(server_url)
        task = asyncio.create_task(client.run_test("both", duration, rate=10))
        tasks.append(task)
        await asyncio.sleep(0.1)  # Stagger client connections
    
    await asyncio.gather(*tasks)
    logger.info("Stress test completed")

def main():
    parser = argparse.ArgumentParser(description="WebSocket client test for hand tracking data")
    parser.add_argument("--server", default="ws://localhost:8765", help="WebSocket server URL")
    parser.add_argument("--mode", choices=["both", "left", "right", "alternate"], 
                        default="both", help="Test mode")
    parser.add_argument("--duration", type=int, default=10, help="Test duration in seconds")
    parser.add_argument("--rate", type=int, default=30, help="Message rate per second")
    parser.add_argument("--stress", action="store_true", help="Run stress test with multiple clients")
    parser.add_argument("--clients", type=int, default=5, help="Number of clients for stress test")
    
    args = parser.parse_args()
    
    logger.info(f"WebSocket Client Test")
    logger.info(f"Server: {args.server}")
    logger.info(f"Mode: {args.mode}")
    logger.info(f"Duration: {args.duration}s")
    logger.info(f"Rate: {args.rate} msg/s")
    
    if args.stress:
        asyncio.run(stress_test(args.server, args.clients, args.duration))
    else:
        client = HandTrackingClient(args.server)
        asyncio.run(client.run_test(args.mode, args.duration, args.rate))

if __name__ == "__main__":
    main()