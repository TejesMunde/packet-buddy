"""Device identification and management."""

import platform
import socket
import uuid
from pathlib import Path
from typing import Tuple

from ..utils.config import config


def get_or_create_device_id() -> str:
    """Get or create persistent device UUID."""
    device_id_path = config.device_id_path
    
    if device_id_path.exists():
        with open(device_id_path, "r") as f:
            return f.read().strip()
    
    # Generate new UUID
    device_id = str(uuid.uuid4())
    
    with open(device_id_path, "w") as f:
        f.write(device_id)
    
    return device_id


def get_device_info() -> Tuple[str, str, str]:
    """Get device information (device_id, os_type, hostname)."""
    device_id = get_or_create_device_id()
    os_type = platform.system()  # Darwin, Windows, Linux
    hostname = socket.gethostname()
    
    return device_id, os_type, hostname
