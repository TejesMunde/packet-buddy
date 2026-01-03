"""Network usage monitoring with psutil."""

import asyncio
import psutil
from datetime import datetime
from typing import Optional

from ..utils.config import config
from .storage import storage


class NetworkMonitor:
    """Async network usage monitor."""
    
    def __init__(self):
        self.running = False
        self.last_sent = 0
        self.last_received = 0
        self.current_speed_sent = 0.0
        self.current_speed_received = 0.0
        self.poll_interval = config.get("monitoring", "poll_interval", default=1)
        self.max_delta = config.get("monitoring", "max_delta_bytes", default=1_000_000_000)
        
        # Buffer for batched writes
        self.pending_writes = []
        self.batch_interval = config.get("monitoring", "batch_write_interval", default=5)
    
    def _get_network_counters(self) -> tuple:
        """Get current network I/O counters."""
        counters = psutil.net_io_counters()
        return counters.bytes_sent, counters.bytes_recv
    
    async def start(self):
        """Start monitoring network usage."""
        self.running = True
        
        # Initialize counters
        self.last_sent, self.last_received = self._get_network_counters()
        
        # Start monitoring and batch writing tasks
        await asyncio.gather(
            self._monitor_loop(),
            self._batch_write_loop(),
        )
    
    async def _monitor_loop(self):
        """Main monitoring loop."""
        while self.running:
            try:
                # Get current counters
                current_sent, current_received = self._get_network_counters()
                
                # Calculate deltas
                delta_sent = current_sent - self.last_sent
                delta_received = current_received - self.last_received
                
                # Detect counter reset (system sleep/resume or counter overflow)
                if delta_sent < 0 or delta_received < 0:
                    # Counter reset detected, skip this sample
                    self.last_sent = current_sent
                    self.last_received = current_received
                    await asyncio.sleep(self.poll_interval)
                    continue
                
                # Anomaly detection: skip unreasonably large deltas
                if delta_sent > self.max_delta or delta_received > self.max_delta:
                    # Likely a system issue, skip
                    self.last_sent = current_sent
                    self.last_received = current_received
                    await asyncio.sleep(self.poll_interval)
                    continue
                
                # Update current speed (bytes per second)
                self.current_speed_sent = delta_sent / self.poll_interval
                self.current_speed_received = delta_received / self.poll_interval
                
                # Add to pending writes buffer
                if delta_sent > 0 or delta_received > 0:
                    self.pending_writes.append({
                        "bytes_sent": delta_sent,
                        "bytes_received": delta_received,
                        "timestamp": datetime.utcnow()
                    })
                
                # Update last values
                self.last_sent = current_sent
                self.last_received = current_received
                
            except Exception as e:
                print(f"Monitor loop error: {e}")
            
            await asyncio.sleep(self.poll_interval)
    
    async def _batch_write_loop(self):
        """Batch write pending data to SQLite."""
        while self.running:
            await asyncio.sleep(self.batch_interval)
            
            if not self.pending_writes:
                continue
            
            try:
                # Flush pending writes to database
                for entry in self.pending_writes:
                    storage.insert_usage(
                        bytes_sent=entry["bytes_sent"],
                        bytes_received=entry["bytes_received"],
                        timestamp=entry["timestamp"]
                    )
                
                # Clear buffer
                self.pending_writes.clear()
                
            except Exception as e:
                print(f"Batch write error: {e}")
    
    async def stop(self):
        """Stop monitoring gracefully."""
        self.running = False
        
        # Flush any remaining writes
        if self.pending_writes:
            for entry in self.pending_writes:
                try:
                    storage.insert_usage(
                        bytes_sent=entry["bytes_sent"],
                        bytes_received=entry["bytes_received"],
                        timestamp=entry["timestamp"]
                    )
                except Exception as e:
                    print(f"Final flush error: {e}")
        
        self.pending_writes.clear()
    
    def get_current_speed(self) -> tuple:
        """Get current upload/download speed."""
        return self.current_speed_sent, self.current_speed_received


# Global monitor instance
monitor = NetworkMonitor()
