#!/usr/bin/env python3
import yaml
import os
import shutil
import time
import subprocess
from shutil import which
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
from mcrcon import MCRcon

# ---------------- CONFIGURATION ----------------
MV_PORTALS_FILE = "/data/plugins/Multiverse-Portals/portals.yml"
DYNMAP_MARKERS_FILE = "/data/plugins/dynmap/markers/portals.yml"

# RCON settings
RCON_HOST = os.environ.get("RCON_HOST", "localhost")
RCON_PORT = int(os.environ.get("RCON_PORT", 25575))
RCON_PASSWORD = os.environ.get("RCON_PASSWORD", "changeme")

# Docker container name (pour le fallback)
MINECRAFT_CONTAINER = os.environ.get("MINECRAFT_CONTAINER", "minecraft")

# Mapping des mondes pour Dynmap
world_name_mapping = {
    "world": "Pangermanie",                                  #A RECUPERER
    "world_nether": "Nether",                                #A RECUPERER
    "world_the_end": "Ender",                                #A RECUPERER
    "world2": "Terres Sauvages"                              #A RECUPERER
}

# ---- Vérifications utilitaires ----
def is_executable_available(cmd):
    return which(cmd) is not None

# ---- Fonction de rechargement Dynmap ----
def reload_dynmap():
    # 1️ Essai via RCON
    try:
        with MCRcon(RCON_HOST, RCON_PASSWORD, port=RCON_PORT) as mcr:
            resp = mcr.command("dynmap reload")
            print(f"[OK] Dynmap rechargé via RCON : {resp}")
            return
    except Exception as e:
        print(f"[WARN] Impossible de recharger Dynmap via RCON : {e}")

    # 2️ Essai via Docker exec
    if not is_executable_available("docker"):
        print("[WARN] Docker non trouvé, impossible de recharger Dynmap via Docker exec")
        print("[WARN] Dynmap n'a pas été rechargé automatiquement")
        return

    try:
        result = subprocess.run(
            ["docker", "exec", MINECRAFT_CONTAINER, "rcon-cli", "dynmap", "reload"],
            check=True,
            capture_output=True,
            text=True
        )
        print(f"[OK] Dynmap rechargé via Docker exec : {result.stdout.strip()}")
        return
    except FileNotFoundError:
        print("[WARN] rcon-cli non trouvé dans le container, Dynmap n'a pas été rechargé automatiquement")
    except subprocess.CalledProcessError as e:
        print(f"[WARN] Échec du rechargement via Docker exec : {e.stderr.strip()}")

# ---------------- FONCTION PRINCIPALE ----------------
def update_dynmap_portals():
    if not os.path.exists(MV_PORTALS_FILE):
        print(f"[ERREUR] Le fichier Multiverse-Portals n'existe pas : {MV_PORTALS_FILE}")
        return

    # Charger les portails Multiverse
    try:
        with open(MV_PORTALS_FILE, "r") as f:
            portals_data = yaml.safe_load(f) or {}
    except Exception as e:
        print(f"[ERREUR] Impossible de lire {MV_PORTALS_FILE} : {e}")
        return

    portals = portals_data.get("portals", {})
    if not portals:
        print("[INFO] Aucun portail trouvé dans portals.yml")
        return

    # Backup du fichier Dynmap
    if os.path.exists(DYNMAP_MARKERS_FILE):
        os.makedirs(os.path.dirname(DYNMAP_MARKERS_FILE), exist_ok=True)
        backup_file = DYNMAP_MARKERS_FILE + ".bak"
        try:
            shutil.copy2(DYNMAP_MARKERS_FILE, backup_file)
            print(f"[INFO] Backup créé : {backup_file}")
        except Exception as e:
            print(f"[WARN] Impossible de créer le backup : {e}")


    # Structure Dynmap
    dynmap_markers = {
        "markersets": {
            "portals": {
                "label": "Portails",
                "hide_by_default": False,
                "markers": {}
            }
        }
    }

    for portal_name, portal_info in portals.items():
        world_id = portal_info.get("world")
        if world_id not in world_name_mapping:
            continue
        x, y, z = portal_info.get("x"), portal_info.get("y"), portal_info.get("z")
        if None in (x, y, z):
            continue
        marker = {
            "x": x,
            "y": y,
            "z": z,
            "world": world_name_mapping[world_id],
            "icon": "green",
            "label": portal_name
        }
        dynmap_markers["markersets"]["portals"]["markers"][portal_name] = marker

    # Écrire le fichier Dynmap
    try:
        os.makedirs(os.path.dirname(DYNMAP_MARKERS_FILE), exist_ok=True)
        with open(DYNMAP_MARKERS_FILE, "w") as f:
            yaml.dump(dynmap_markers, f, sort_keys=False)
        print(f"[OK] Fichier Dynmap mis à jour : {DYNMAP_MARKERS_FILE}")
    except Exception as e:
        print(f"[ERREUR] Impossible d'écrire {DYNMAP_MARKERS_FILE} : {e}")
        return

    # ---- Recharger Dynmap avec fallback ----
    reload_dynmap()

# ---------------- Watchdog ----------------
class PortalsHandler(FileSystemEventHandler):
    def on_modified(self, event):
        if event.src_path == MV_PORTALS_FILE:
            print(f"[INFO] Changement détecté sur {MV_PORTALS_FILE}")
            update_dynmap_portals()

# ---------------- Main ----------------
if __name__ == "__main__":
    # Lancement initial
    update_dynmap_portals()

    # Surveillance
    event_handler = PortalsHandler()
    observer = Observer()
    observer.schedule(event_handler, path=os.path.dirname(MV_PORTALS_FILE), recursive=False)
    observer.start()
    print("[INFO] Surveillance activée sur portals.yml")

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()
