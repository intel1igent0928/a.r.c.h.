## NetworkManager — Autoload singleton
## Handles ENet peer creation, player slot tracking, and game-state synchronisation.
## Add to project as Autoload: Project → Project Settings → Autoload → network_manager.gd → name "NetworkManager"
extends Node

# ── Signals ───────────────────────────────────────────────────────────────────
signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal connection_failed()
signal server_disconnected()
signal server_created()
signal all_players_ready()
signal grid_snapshot_received(rows: Array)

# ── Constants ─────────────────────────────────────────────────────────────────
const DEFAULT_PORT   := 7432
const MAX_PLAYERS    := 2
const PROTOCOL_VER   := 1

# ── State ─────────────────────────────────────────────────────────────────────
var is_host          := false
var is_online        := false
var connected_peers  := {}   # peer_id -> { "ready": bool }
var local_name       := "Player"

# ── Setup ─────────────────────────────────────────────────────────────────────
func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

# ── Public API ────────────────────────────────────────────────────────────────

## Create an ENet server and wait for one client.
func create_server(port: int = DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err  := peer.create_server(port, MAX_PLAYERS)
	if err != OK:
		push_error("NetworkManager: create_server failed: %s" % error_string(err))
		return err
	multiplayer.multiplayer_peer = peer
	is_host   = true
	is_online = true
	# Register host itself
	connected_peers[1] = { "ready": false }
	print("NetworkManager: Server started on port %d" % port)
	server_created.emit()
	return OK

## Connect to a remote host as a client.
func join_server(ip: String, port: int = DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err  := peer.create_client(ip, port)
	if err != OK:
		push_error("NetworkManager: join_server failed: %s" % error_string(err))
		return err
	multiplayer.multiplayer_peer = peer
	is_host   = false
	is_online = true
	print("NetworkManager: Connecting to %s:%d …" % [ip, port])
	return OK

## Disconnect cleanly and reset state.
func disconnect_network() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	connected_peers.clear()
	is_host   = false
	is_online = false

## Mark local player as ready; host checks if all are ready.
func set_local_ready() -> void:
	var my_id := multiplayer.get_unique_id()
	if connected_peers.has(my_id):
		connected_peers[my_id]["ready"] = true
	_notify_ready.rpc(my_id)

## Returns true when every connected peer has sent "ready".
func all_ready() -> bool:
	if connected_peers.is_empty():
		return false
	for data in connected_peers.values():
		if not data.get("ready", false):
			return false
	return true

## Returns peer IDs of all remote players (excludes local).
func get_remote_peer_ids() -> Array:
	var my_id := multiplayer.get_unique_id()
	var result: Array = []
	for pid in connected_peers.keys():
		if pid != my_id:
			result.append(pid)
	return result

## Human-readable connection status string for UI.
func get_status_text() -> String:
	if not is_online:
		return ""
	var count := connected_peers.size()
	if is_host:
		if count < 2:
			return "Ожидание игрока…"
		else:
			return "Игрок 2 подключён ✓"
	else:
		return "Подключён к хосту ✓"

# ── RPC ───────────────────────────────────────────────────────────────────────

## Broadcast readiness to all peers.
@rpc("any_peer", "reliable")
func _notify_ready(peer_id: int) -> void:
	if connected_peers.has(peer_id):
		connected_peers[peer_id]["ready"] = true
		print("NetworkManager: peer %d is ready" % peer_id)
	if all_ready():
		all_players_ready.emit()

## Host → all: send the full maze grid as a snapshot on late join.
@rpc("authority", "reliable")
func receive_grid_snapshot(rows: Array) -> void:
	print("NetworkManager: received grid snapshot (%d rows)" % rows.size())
	grid_snapshot_received.emit(rows)

## Send snapshot from host to a specific new peer.
func send_grid_snapshot_to(peer_id: int, rows: Array) -> void:
	if not multiplayer.is_server():
		return
	receive_grid_snapshot.rpc_id(peer_id, rows)

# ── Internal callbacks ────────────────────────────────────────────────────────

func _on_peer_connected(peer_id: int) -> void:
	print("NetworkManager: peer connected — id=%d" % peer_id)
	connected_peers[peer_id] = { "ready": false }
	player_connected.emit(peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
	print("NetworkManager: peer disconnected — id=%d" % peer_id)
	connected_peers.erase(peer_id)
	player_disconnected.emit(peer_id)

func _on_connected_to_server() -> void:
	var my_id := multiplayer.get_unique_id()
	connected_peers[my_id] = { "ready": false }
	print("NetworkManager: connected to server, my id=%d" % my_id)
	player_connected.emit(my_id)

func _on_connection_failed() -> void:
	push_error("NetworkManager: connection failed")
	is_online = false
	connection_failed.emit()

func _on_server_disconnected() -> void:
	push_error("NetworkManager: server disconnected")
	disconnect_network()
	server_disconnected.emit()
