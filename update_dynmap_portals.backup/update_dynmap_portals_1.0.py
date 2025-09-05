#!/usr/bin/env python3
import yaml
import os
import subprocess

# CONFIGURATION : modifie ces chemins selon ton serveur
MV_PORTALS_FILE = "/minecraft/plugins/Multiverse-Portals/portals.yml"
DYNMAP_MARKERS_FILE = "/minecraft/plugins/dynmap/markers/portals.yml"

# Si le serveur tourne dans Docker sous screen/tmux
SERVER_NAME = "minecraft_server"  # nom du conteneur Docker

# Mapping des mondes pour Dynmap
world_name_mapping = {
    "world": "Pangermanie",
    "world_nether": "Nether",
    "world_the_end": "Ender",
    "world2": "Terres Sauvages"
}

def update_dynmap_portals():
    if not os.path.exists(MV_PORTALS_FILE):
        print(f"Le fichier Multiverse-Portals n'existe pas : {MV_PORTALS_FILE}")
        return

    # Charger les portails Multiverse
    with open(MV_PORTALS_FILE, "r") as f:
        portals_data = yaml.safe_load(f)

    # Structure Dynmap
    dynmap_markers = {"markersets": {"portals": {"label": "Portails", "hide_by_default": False, "markers": {}}}}

    for portal_name, portal_info in portals_data.get("portals", {}).items():
        world_id = portal_info.get("world")
        if world_id not in world_name_mapping:
            continue

        marker = {
            "x": portal_info.get("x"),
            "y": portal_info.get("y"),
            "z": portal_info.get("z"),
            "world": world_id,
            "icon": "green",
            "label": portal_name
        }
        dynmap_markers["markersets"]["portals"]["markers"][portal_name] = marker

    # Écrire le fichier Dynmap
    os.makedirs(os.path.dirname(DYNMAP_MARKERS_FILE), exist_ok=True)
    with open(DYNMAP_MARKERS_FILE, "w") as f:
        yaml.dump(dynmap_markers, f, sort_keys=False)

    print(f"[OK] Fichier Dynmap mis à jour : {DYNMAP_MARKERS_FILE}")

    # Recharger Dynmap dans le conteneur Docker
    try:
        subprocess.run([
            "docker", "exec", "-i", SERVER_NAME,
            "rcon-cli", "dynmap reload"
        ], check=True)
        print("[OK] Dynmap rechargé automatiquement dans Docker")
    except Exception as e:
        print(f"[ERREUR] Impossible de recharger Dynmap : {e}")

if __name__ == "__main__":
    update_dynmap_portals()
