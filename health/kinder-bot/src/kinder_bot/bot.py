import os
import time
import requests
import shutil
import subprocess
from pydantic import BaseModel
from typing import Optional

KB_SSH_USER = os.environ.get('KB_SSH_USER', 'root')
KB_BOT_TOKEN = os.environ.get('KB_BOT_TOKEN', '')
KB_SECRET_PASSWORD = os.environ.get('KB_SECRET_PASSWORD', '')

MOUNTED_DIR = f"/mnt/kinder_bot_data"
DEFAULT_DIR = "/app/.kinder-bot.pigovsky.com"

ADMINS_FILE = os.path.join(MOUNTED_DIR, "admins.txt")
SSH_KEY_PATH = os.path.join(MOUNTED_DIR, "id_ed25519")
VOICE_DIR = os.path.join(MOUNTED_DIR, "voice")

class MessageChat(BaseModel):
    id: int

class Voice(BaseModel):
    file_id: str
    duration: int
    mime_type: Optional[str] = None
    file_size: Optional[int] = None

class Message(BaseModel):
    message_id: int
    text: Optional[str] = None
    voice: Optional[Voice] = None
    chat: MessageChat

class Update(BaseModel):
    update_id: int
    message: Optional[Message] = None

def sync_default_files():
    if not os.path.exists(DEFAULT_DIR):
        print(f"Default directory {DEFAULT_DIR} does not exist. Skipping sync.")
        return

    default_version_file = os.path.join(DEFAULT_DIR, "VERSION")
    mounted_version_file = os.path.join(MOUNTED_DIR, "VERSION")
    
    default_version = ""
    if os.path.exists(default_version_file):
        with open(default_version_file, "r") as f:
            default_version = f.read().strip()
            
    mounted_version = ""
    if os.path.exists(mounted_version_file):
        with open(mounted_version_file, "r") as f:
            mounted_version = f.read().strip()
        
    if default_version != mounted_version:
        print(f"Version mismatch: default '{default_version}', mounted '{mounted_version}'. Syncing files...")
        for item in os.listdir(DEFAULT_DIR):
            s = os.path.join(DEFAULT_DIR, item)
            d = os.path.join(MOUNTED_DIR, item)
            if os.path.isdir(s):
                if os.path.exists(d):
                    shutil.rmtree(d)
                shutil.copytree(s, d)
            else:
                shutil.copy2(s, d)
    else:
        print(f"Versions match ({mounted_version}). No sync needed.")

def setup_ssh():
    if not os.path.exists(SSH_KEY_PATH):
        print("Generating SSH key pair...")
        subprocess.run(["ssh-keygen", "-t", "ed25519", "-N", "", "-f", SSH_KEY_PATH], check=True)
        
        pub_key_path = SSH_KEY_PATH + ".pub"
        with open(pub_key_path, "r") as f:
            public_key = f.read().strip()
            
        print("Adding public key to host authorized_keys...")
        host_ssh_dir = "/mnt/host_ssh"
        auth_keys_path = os.path.join(host_ssh_dir, "authorized_keys")
        if os.path.exists(host_ssh_dir):
            with open(auth_keys_path, "a") as f:
                f.write(f"\n{public_key}\n")
            print("Successfully added to authorized_keys.")
        else:
            print(f"Warning: {host_ssh_dir} does not exist. Cannot add key to host automatically.")
    else:
        print("SSH key pair already exists.")
        
    # Set proper permissions for SSH key
    os.chmod(SSH_KEY_PATH, 0o600)

def get_admins() -> set[str]:
    if not os.path.exists(ADMINS_FILE):
        return set()
    with open(ADMINS_FILE, "r") as f:
        return set(line.strip() for line in f if line.strip())

def add_admin(chat_id: str):
    admins = get_admins()
    if chat_id not in admins:
        with open(ADMINS_FILE, "a") as f:
            f.write(f"{chat_id}\n")

def is_admin(chat_id: str) -> bool:
    return chat_id in get_admins()

def send_message(chat_id: str, text: str):
    if not text:
        return
    url = f"https://api.telegram.org/bot{KB_BOT_TOKEN}/sendMessage"
    
    # Telegram has a max message length of 4096 characters
    max_length = 4000
    if len(text) > max_length:
        text = text[:max_length] + "\n...[truncated]"
        
    payload = {
        "chat_id": chat_id,
        "text": text
    }
    try:
        requests.post(url, json=payload, timeout=10)
    except Exception as e:
        print(f"Failed to send message: {e}")

def run_ssh_command(cmd: str) -> tuple[str, str]:
    # Use SSH to execute the command on the host machine
    # -o StrictHostKeyChecking=no bypasses the prompt for unknown hosts
    # -i specifies the identity file
    
    # Run the command with bash -c to support complex commands and pipelines,
    # and use cd to set the working directory
    ssh_cmd = [
        "ssh", 
        "-o", "StrictHostKeyChecking=no", 
        "-i", SSH_KEY_PATH, 
        f"{KB_SSH_USER}@host.docker.internal",
        f"cd ~/.kinder-bot.pigovsky.com && {cmd}"
    ]
    
    try:
        result = subprocess.run(
            ssh_cmd, 
            capture_output=True, 
            text=True, 
            timeout=60
        )
        return result.stdout, result.stderr
    except subprocess.TimeoutExpired as e:
        return e.stdout.decode() if e.stdout else "", "Command timed out."
    except Exception as e:
        return "", str(e)

def download_voice(file_id: str) -> Optional[str]:
    url = f"https://api.telegram.org/bot{KB_BOT_TOKEN}/getFile"
    try:
        resp = requests.get(url, params={"file_id": file_id}, timeout=10)
        if resp.status_code == 200:
            data = resp.json()
            if data.get("ok"):
                file_path = data["result"]["file_path"]
                download_url = f"https://api.telegram.org/file/bot{KB_BOT_TOKEN}/{file_path}"
                
                # Create voice dir if not exists
                os.makedirs(VOICE_DIR, exist_ok=True)
                
                # Telegram voice files are usually in OGG OPUS format
                local_filename = f"{file_id}.oga"
                local_path = os.path.join(VOICE_DIR, local_filename)
                
                # It's important to use chunked downloading for binary files
                r = requests.get(download_url, stream=True, timeout=30)
                r.raise_for_status()
                with open(local_path, 'wb') as f:
                    for chunk in r.iter_content(chunk_size=8192):
                        if chunk:
                            f.write(chunk)
                return local_filename
    except Exception as e:
        print(f"Failed to download voice: {e}")
    return None

def poll_updates():
    offset = None
    print("Starting bot polling...")
    while True:
        url = f"https://api.telegram.org/bot{KB_BOT_TOKEN}/getUpdates"
        params = {"timeout": 30}
        if offset:
            params["offset"] = offset
            
        try:
            resp = requests.get(url, params=params, timeout=40)
            if resp.status_code == 200:
                data = resp.json()
                if not data.get("ok"):
                    time.sleep(1)
                    continue
                
                for item in data.get("result", []):
                    try:
                        update = Update(**item)
                        offset = update.update_id + 1
                        
                        if update.message:
                            chat_id = str(update.message.chat.id)
                            
                            # Handle text messages
                            if update.message.text:
                                text = update.message.text.strip()
                                
                                if text.startswith("login "):
                                    pwd = text.split(" ", 1)[1]
                                    if pwd == KB_SECRET_PASSWORD:
                                        add_admin(chat_id)
                                        send_message(chat_id, "Login successful. You are now an admin.")
                                    else:
                                        send_message(chat_id, "Invalid password.")
                                elif is_admin(chat_id):
                                    send_message(chat_id, f"Executing: {text}")
                                    out, err = run_ssh_command(text)
                                    resp_text = ""
                                    if out:
                                        resp_text += f"STDOUT:\n```\n{out}\n```\n"
                                    if err:
                                        resp_text += f"STDERR:\n```\n{err}\n```\n"
                                    if not resp_text:
                                        resp_text = "Command executed successfully (no output)."
                                    send_message(chat_id, resp_text)
                                else:
                                    send_message(chat_id, "You are not authorized. Use 'login {secret-password}' to authenticate.")
                                    
                            # Handle voice messages
                            elif update.message.voice and is_admin(chat_id):
                                send_message(chat_id, f"Received voice message (size: {update.message.voice.file_size} bytes), processing...")
                                voice_filename = download_voice(update.message.voice.file_id)
                                if voice_filename:
                                    # Voice files are saved to the mounted dir, so they are accessible on the host
                                    host_voice_path = f"~/.kinder-bot.pigovsky.com/voice/{voice_filename}"
                                    cmd = f"cvlc --play-and-exit {host_voice_path}"
                                    send_message(chat_id, f"Executing: {cmd}")
                                    out, err = run_ssh_command(cmd)
                                    
                                    resp_text = ""
                                    if out:
                                        resp_text += f"STDOUT:\n```\n{out}\n```\n"
                                    if err:
                                        resp_text += f"STDERR:\n```\n{err}\n```\n"
                                    if not resp_text:
                                        resp_text = "Voice message played successfully."
                                    send_message(chat_id, resp_text)
                                else:
                                    send_message(chat_id, "Failed to download voice message.")

                    except Exception as e:
                        print(f"Error processing update: {e}")
                        # Move past this update if it caused an error
                        if "update_id" in item:
                            offset = item["update_id"] + 1
        except requests.exceptions.Timeout:
            # Expected during long polling
            pass
        except Exception as e:
            print(f"Error polling: {e}")
            time.sleep(5)

if __name__ == "__main__":
    if not os.path.exists(MOUNTED_DIR):
        try:
            os.makedirs(MOUNTED_DIR, exist_ok=True)
        except Exception as e:
            print(f"Error creating MOUNTED_DIR: {e}")

    sync_default_files()
    setup_ssh()
    poll_updates()
