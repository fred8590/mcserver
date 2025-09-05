#!/usr/bin/env python3
import yaml
import os
import shutil
import subprocess
import time
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

# ---------------- CONFIGURATION ----------------
MV_PORTALS_FILE = "/minecraft/plugins/Multiverse-Portals/portals.yml"
DYNMAP_MARKERS_FILE = "/minecraft/plugins/dynmap/markers/portals.yml"

SERVER_NAME = "minecraft_server"  # nom du conteneur Docker     #A RECUPERER

# Mapping des mondes pour Dynmap
world_name_mapping = {
    "world": "Pangermanie",                                  #A RECUPERER
    "world_nether": "Nether",                                #A RECUPERER
    "world_the_end": "Ender",                                #A RECUPERER
    "world2": "Terres Sauvages"                              #A RECUPERER
}

# ---------------- FONCTION PRINCIPALE ----------------
def update_dynmap_portals():
    if not os.path.exists(MV_PORTALS_FILE):
        print(f"[ERREUR] Le fichier Multiverse-Portals n'existe pas : {MV_PORTALS_FILE}")
        return

    # Charger les portails Multiverse
    with open(MV_PORTALS_FILE, "r") as f:
        portals_data = yaml.safe_load(f) or {}

    # Backup du fichier Dynmap existant
    if os.path.exists(DYNMAP_MARKERS_FILE):
        shutil.copy2(DYNMAP_MARKERS_FILE, DYNMAP_MARKERS_FILE + ".bak")
        print(f"[INFO] Backup créé : {DYNMAP_MARKERS_FILE}.bak")

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

    for portal_name, portal_info in portals_data.get("portals", {}).items():
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
    os.makedirs(os.path.dirname(DYNMAP_MARKERS_FILE), exist_ok=True)
    with open(DYNMAP_MARKERS_FILE, "w") as f:
        yaml.dump(dynmap_markers, f, sort_keys=False)

    print(f"[OK] Fichier Dynmap mis à jour : {DYNMAP_MARKERS_FILE}")

    # Tente de recharger Dynmap si rcon-cli est présent
    try:
        subprocess.run([
            "docker", "exec", "-i", SERVER_NAME,
            "rcon-cli", "dynmap reload"
        ], check=True)
        print("[OK] Dynmap rechargé automatiquement dans Docker")
    except Exception:
        print("[WARN] rcon-cli non disponible, Dynmap n'a pas été rechargé automatiquement")

# ---------------- Watchdog ----------------
class PortalsHandler(FileSystemEventHandler):
    def on_modified(self, event):
        if event.src_path == MV_PORTALS_FILE:
            print(f"[INFO] Changement détecté sur {MV_PORTALS_FILE}")
            update_dynmap_portals()

# ---------------- EXECUTION ----------------
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
