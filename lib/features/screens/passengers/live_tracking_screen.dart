import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../../../supabase_config.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String tripId;
  final String origin;
  final String destination;

  const LiveTrackingScreen({
    super.key,
    required this.tripId,
    required this.origin,
    required this.destination,
  });

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final MapController _mapController = MapController();
  Timer? _pollingTimer;

  LatLng? _busPosition;
  String _tripStatus = 'scheduled';
  String? _departedAt;
  String? _scheduledDeparture;
  String? _scheduledArrival;
  bool _isLoading = true;
  String? _errorMessage;
  bool _followBus = true;
  bool _mapReady = false;

  // Route details
  List<LatLng> _routePoints = [];
  LatLng? _originLatLng;
  LatLng? _destinationLatLng;

  List<Map<String, dynamic>> _activeIncidents = [];

  // Default center: Phnom Penh
  static const LatLng _defaultCenter = LatLng(11.5564, 104.9282);

  static const Map<String, LatLng> _cityCoordinates = {
    'phnom penh': LatLng(11.5564, 104.9282),
    'takeo': LatLng(10.9904, 104.7845),
    'siem reap': LatLng(13.3633, 103.8564),
    'sihanoukville': LatLng(10.6096, 103.5292),
    'kampot': LatLng(10.5942, 104.1814),
    'battambang': LatLng(13.0957, 103.2022),
    'poipet': LatLng(13.6561, 102.5630),
    'kampong cham': LatLng(11.9934, 105.4645),
    'kampong chhnang': LatLng(12.2500, 104.6667),
    'kampong speu': LatLng(11.4533, 104.5208),
    'kampong thom': LatLng(12.7111, 104.8883),
    'kandal': LatLng(11.4833, 104.9500),
    'kep': LatLng(10.4833, 104.3167),
    'koh kong': LatLng(11.6153, 102.9838),
    'kratie': LatLng(12.4833, 106.0167),
    'mondulkiri': LatLng(12.4500, 107.2000),
    'oddar meanchey': LatLng(14.1750, 103.5167),
    'pailin': LatLng(12.8489, 102.6092),
    'preah vihear': LatLng(13.8000, 104.9667),
    'prey veng': LatLng(11.4833, 105.3333),
    'pursat': LatLng(12.5333, 103.9167),
    'ratanakiri': LatLng(13.7333, 107.0000),
    'stung treng': LatLng(13.5250, 105.9667),
    'svay rieng': LatLng(11.0833, 105.8000),
    'tboung khmum': LatLng(11.9167, 105.6667),
  };

  Future<LatLng?> _resolveCoordinates(String cityName) async {
    final nameClean = cityName.trim().toLowerCase();
    if (_cityCoordinates.containsKey(nameClean)) {
      return _cityCoordinates[nameClean];
    }

    try {
      final query = Uri.encodeComponent('$cityName, Cambodia');
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'com.example.bus_express'},
      );

      if (response.statusCode == 200) {
        final list = json.decode(response.body) as List;
        if (list.isNotEmpty) {
          final first = list.first;
          final lat = double.parse(first['lat']);
          final lon = double.parse(first['lon']);
          return LatLng(lat, lon);
        }
      }
    } catch (e) {
      debugPrint('[Geocoder] Nominatim error for $cityName: $e');
    }
    return null;
  }

  Future<List<LatLng>> _fetchRoutePolyline(
    LatLng origin,
    LatLng destination,
  ) async {
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'com.example.bus_express'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final geometry = routes.first['geometry'];
          final coordinates = geometry['coordinates'] as List?;
          if (coordinates != null) {
            return coordinates.map<LatLng>((coord) {
              return LatLng(
                (coord[1] as num).toDouble(),
                (coord[0] as num).toDouble(),
              );
            }).toList();
          }
        }
      }
    } catch (e) {
      debugPrint('[Routing] OSRM error: $e');
    }
    return [];
  }

  Future<void> _loadRoutePath() async {
    final originPos = await _resolveCoordinates(widget.origin);
    final destPos = await _resolveCoordinates(widget.destination);

    if (originPos != null && destPos != null) {
      if (mounted) {
        setState(() {
          _originLatLng = originPos;
          _destinationLatLng = destPos;
        });
      }
      await _updateRoutePath();
    }
  }

  Future<void> _updateRoutePath() async {
    // If the bus has departed and we have its live position, draw directions from the bus to the destination!
    // Otherwise, draw from the origin station to the destination.
    final startPos = (_tripStatus == 'in_progress' && _busPosition != null)
        ? _busPosition
        : (_originLatLng ?? _busPosition);
    final destPos = _destinationLatLng;

    if (startPos != null && destPos != null) {
      final points = await _fetchRoutePolyline(startPos, destPos);
      if (mounted && points.isNotEmpty) {
        setState(() {
          _routePoints = points;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _loadRoutePath();
    _subscribeToRealtime();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchIncidents() async {
    try {
      final data = await SupabaseConfig.client
          .from('incidents')
          .select('type, description, created_at')
          .eq('trip_id', widget.tripId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      debugPrint('[Live Tracking] Error fetching incidents: $e');
      return [];
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _errorMessage = null);
    try {
      final results = await Future.wait<dynamic>([
        SupabaseConfig.client
            .from('trips')
            .select('''
              latitude, longitude, status, departed_at,
              schedules (
                departure_time,
                arrival_time
              )
            ''')
            .eq('id', widget.tripId)
            .maybeSingle(),
        _fetchIncidents(),
      ]);

      final data = results[0] as Map<String, dynamic>?;
      final incidents = results[1] as List<Map<String, dynamic>>;

      if (mounted) {
        setState(() {
          _activeIncidents = incidents;
        });
      }

      if (mounted && data != null) {
        final lat = data['latitude'];
        final lng = data['longitude'];
        final schedule = data['schedules'] as Map<String, dynamic>?;
        setState(() {
          _tripStatus = data['status'] ?? 'scheduled';
          _departedAt = data['departed_at'];
          _scheduledDeparture = schedule?['departure_time'] as String?;
          _scheduledArrival = schedule?['arrival_time'] as String?;
          if (lat != null && lng != null) {
            _busPosition = LatLng(
              (lat as num).toDouble(),
              (lng as num).toDouble(),
            );
          }
          _isLoading = false;
        });

        // Update route polyline to start from the bus's live position
        _updateRoutePath();

        // Move map to bus position if map is ready
        if (_busPosition != null && _mapReady) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_mapReady) {
              _mapController.move(_busPosition!, 13);
            }
          });
        }
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Trip not found. It may have been cancelled.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not load tracking data. Check your connection.';
          _isLoading = false;
        });
      }
    }
  }

  void _subscribeToRealtime() {
    // Poll the database every 5 seconds to guarantee resilient tracking 
    // avoiding WebSocket timeouts (RealtimeSubscribeException).
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;
      try {
        final results = await Future.wait<dynamic>([
          SupabaseConfig.client
              .from('trips')
              .select('''
                latitude, longitude, status, departed_at,
                schedules (
                  departure_time,
                  arrival_time
                )
              ''')
              .eq('id', widget.tripId)
              .maybeSingle(),
          _fetchIncidents(),
        ]);

        final data = results[0] as Map<String, dynamic>?;
        final incidents = results[1] as List<Map<String, dynamic>>;

        if (mounted) {
          setState(() {
            _activeIncidents = incidents;
          });
        }

        if (data != null && mounted) {
          final lat = data['latitude'];
          final lng = data['longitude'];
          final schedule = data['schedules'] as Map<String, dynamic>?;

          final oldBusPosition = _busPosition;
          final oldTripStatus = _tripStatus;

          setState(() {
            _tripStatus = data['status'] ?? _tripStatus;
            _departedAt = data['departed_at'] ?? _departedAt;
            _scheduledDeparture = schedule?['departure_time'] as String? ?? _scheduledDeparture;
            _scheduledArrival = schedule?['arrival_time'] as String? ?? _scheduledArrival;
            if (lat != null && lng != null) {
              _busPosition = LatLng(
                (lat as num).toDouble(),
                (lng as num).toDouble(),
              );
            }
          });

          // Recalculate route polyline if position changed OR trip status changed
          // (e.g., scheduled→in_progress updates route from origin→dest to bus→dest)
          if (_busPosition != oldBusPosition || _tripStatus != oldTripStatus) {
            _updateRoutePath();
          }

          // Auto-follow bus on map if ready
          if (_busPosition != null && _followBus && _mapReady) {
            _mapController.move(_busPosition!, _mapController.camera.zoom);
          }
        }
      } catch (e) {
        debugPrint('[Live Tracking] Polling error: $e');
      }
    });
  }

  int get _totalDelayMinutes {
    int total = 0;
    for (final incident in _activeIncidents) {
      final type = incident['type'] as String? ?? 'other';
      if (type == 'breakdown') {
        total += 30; // Breakdown: around 30 mins delay
      } else if (type == 'accident') {
        total += 45; // Accident: around 45 mins delay
      } else if (type == 'delay') {
        total += 20; // Traffic delay: around 20 mins
      } else {
        total += 15; // Other: around 15 mins
      }
    }
    return total;
  }

  String get _estimatedArrivalTime {
    if (_scheduledArrival == null) return '—';
    try {
      final aParts = _scheduledArrival!.split(':');
      final aHour = int.parse(aParts[0]);
      final aMin = int.parse(aParts[1]);

      final now = DateTime.now();
      var arrivalDateTime = DateTime(now.year, now.month, now.day, aHour, aMin);

      // Handle overnight trips: if arrival time is before departure time,
      // the arrival is on the next calendar day.
      if (_scheduledDeparture != null) {
        final dParts = _scheduledDeparture!.split(':');
        final dHour = int.parse(dParts[0]);
        final dMin = int.parse(dParts[1]);
        final departureDateTime = DateTime(now.year, now.month, now.day, dHour, dMin);
        if (arrivalDateTime.isBefore(departureDateTime)) {
          arrivalDateTime = arrivalDateTime.add(const Duration(days: 1));
        }
      }

      arrivalDateTime = arrivalDateTime.add(Duration(minutes: _totalDelayMinutes));

      final h = arrivalDateTime.hour;
      final m = arrivalDateTime.minute.toString().padLeft(2, '0');
      final period = h >= 12 ? 'PM' : 'AM';
      final dh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      return '$dh:$m $period';
    } catch (_) {
      return _scheduledArrival!;
    }
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(36),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: Color(0xFFEF4444),
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadInitialData();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.origin} → ${widget.destination}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            Text(
              'Live Tracking',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
        ),
        actions: [
          // Follow bus toggle
          IconButton(
            icon: Icon(
              _followBus
                  ? Icons.directions_bus_rounded
                  : Icons.directions_bus_outlined,
              color: Colors.white,
            ),
            tooltip: _followBus ? 'Following bus' : 'Follow bus',
            onPressed: () {
              setState(() => _followBus = !_followBus);
              if (_followBus && _busPosition != null && _mapReady) {
                _mapController.move(_busPosition!, _mapController.camera.zoom);
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : Stack(
              children: [
                // ── MAP ────────────────────────────────────────────────
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter:
                        _busPosition ?? _originLatLng ?? _defaultCenter,
                    initialZoom: 12,
                    onTap: (_, _) => setState(() => _followBus = false),
                    onMapReady: () {
                      setState(() => _mapReady = true);
                      if (_busPosition != null) {
                        _mapController.move(_busPosition!, 12);
                      }
                    },
                  ),
                  children: [
                    // OpenStreetMap tile layer (free, no API key)
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.bus_booking',
                      maxZoom: 19,
                    ),

                    // Route Polyline Layer (100% Free road-routing via OSRM!)
                    if (_routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            strokeWidth: 5.5,
                            color: const Color(
                              0xFF1A73E8,
                            ).withValues(alpha: 0.8),
                            borderColor: const Color(0xFF0D47A1),
                            borderStrokeWidth: 1.5,
                          ),
                        ],
                      ),

                    // Origin and Destination markers
                    MarkerLayer(
                      markers: [
                        // Origin City Departure Point
                        if (_originLatLng != null)
                          Marker(
                            point: _originLatLng!,
                            width: 36,
                            height: 36,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A73E8),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.radio_button_checked_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),

                        // Destination City Point
                        if (_destinationLatLng != null)
                          Marker(
                            point: _destinationLatLng!,
                            width: 36,
                            height: 36,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.flag_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Bus marker
                    if (_busPosition != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _busPosition!,
                            width: 60,
                            height: 60,
                            child: _BusMarker(
                              isMoving: _tripStatus == 'in_progress',
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                // ── STATUS & INCIDENT CARDS (top overlay) ────────────────
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StatusOverlayCard(
                        status: _tripStatus,
                        departedAt: _departedAt,
                        busPosition: _busPosition,
                      ),
                      if (_activeIncidents.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _IncidentAlertBanner(incidents: _activeIncidents),
                      ],
                    ],
                  ),
                ),


                // ── TRIP NOT STARTED overlay (scheduled only) ─────────
                if (_busPosition == null && _tripStatus == 'scheduled')
                  Center(
                    child: Container(
                      margin: const EdgeInsets.all(32),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.schedule_rounded,
                            size: 48,
                            color: Color(0xFF9CA3AF),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Trip Not Started Yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'The bus will appear on the map once the driver starts the trip.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF9CA3AF),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── LOCATING BUS chip (in_progress but no GPS yet) ───
                if (_busPosition == null && _tripStatus == 'in_progress')
                  Positioned(
                    bottom: 130,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _LocatingBusChip(),
                    ),
                  ),


                // ── FOLLOW BUS button (bottom right) ─────────────────
                if (_busPosition != null && !_followBus)
                  Positioned(
                    bottom: 120,
                    right: 16,
                    child: FloatingActionButton.small(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1A73E8),
                      onPressed: () {
                        setState(() => _followBus = true);
                        if (_mapReady) {
                          _mapController.move(
                            _busPosition!,
                            _mapController.camera.zoom,
                          );
                        }
                      },
                      child: const Icon(Icons.my_location_rounded),
                    ),
                  ),

                // ── BOTTOM INFO CARD ──────────────────────────────────
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _BottomInfoCard(
                    origin: widget.origin,
                    destination: widget.destination,
                    busPosition: _busPosition,
                    tripStatus: _tripStatus,
                    scheduledDeparture: _scheduledDeparture,
                    scheduledArrival: _scheduledArrival,
                    estimatedArrival: _estimatedArrivalTime,
                    totalDelay: _totalDelayMinutes,
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── Bus Marker ───────────────────────────────────────────────────────────────

class _BusMarker extends StatefulWidget {
  final bool isMoving;
  const _BusMarker({required this.isMoving});

  @override
  State<_BusMarker> createState() => _BusMarkerState();
}

class _BusMarkerState extends State<_BusMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.2).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) => Transform.scale(
        scale: widget.isMoving ? _pulseAnim.value : 1.0,
        child: child,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: widget.isMoving
              ? const Color(0xFF10B981)
              : const Color(0xFF1A73E8),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color:
                  (widget.isMoving
                          ? const Color(0xFF10B981)
                          : const Color(0xFF1A73E8))
                      .withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          Icons.directions_bus_rounded,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}

// ─── Status Overlay Card ──────────────────────────────────────────────────────

class _StatusOverlayCard extends StatelessWidget {
  final String status;
  final String? departedAt;
  final LatLng? busPosition;

  const _StatusOverlayCard({
    required this.status,
    required this.departedAt,
    required this.busPosition,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case 'in_progress':
        if (busPosition != null) {
          color = const Color(0xFF10B981);
          icon = Icons.play_circle_rounded;
          label = 'Bus is on the way';
        } else {
          color = const Color(0xFFF59E0B);
          icon = Icons.gps_fixed_rounded;
          label = 'Locating bus...';
        }
        break;
      case 'completed':
        color = const Color(0xFF6B7280);
        icon = Icons.check_circle_rounded;
        label = 'Trip completed';
        break;
      case 'cancelled':
        color = const Color(0xFFEF4444);
        icon = Icons.cancel_rounded;
        label = 'Trip cancelled';
        break;
      default:
        color = const Color(0xFF1A73E8);
        icon = Icons.schedule_rounded;
        label = 'Waiting for departure';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                if (departedAt != null && status == 'in_progress')
                  Text(
                    'Departed at ${_formatTime(departedAt!)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
              ],
            ),
          ),
          // Live indicator (only show when we have actual GPS data)
          if (status == 'in_progress' && busPosition != null)
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatTime(String ts) {
    final dt = DateTime.parse(ts).toLocal();
    final h = dt.hour;
    final period = h >= 12 ? 'PM' : 'AM';
    final dh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$dh:${dt.minute.toString().padLeft(2, '0')} $period';
  }
}

// ─── Bottom Info Card ─────────────────────────────────────────────────────────

class _BottomInfoCard extends StatelessWidget {
  final String origin;
  final String destination;
  final LatLng? busPosition;
  final String tripStatus;
  final String? scheduledDeparture;
  final String? scheduledArrival;
  final String? estimatedArrival;
  final int totalDelay;

  const _BottomInfoCard({
    required this.origin,
    required this.destination,
    required this.busPosition,
    required this.tripStatus,
    this.scheduledDeparture,
    this.scheduledArrival,
    this.estimatedArrival,
    this.totalDelay = 0,
  });

  String _formatTime(String t) {
    if (t.isEmpty) return '—';
    try {
      final p = t.split(':');
      final h = int.parse(p[0]);
      final period = h >= 12 ? 'PM' : 'AM';
      final dh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      return '$dh:${p[1]} $period';
    } catch (_) {
      return t;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Row(
            children: [
              // Origin dot
              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A73E8),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 28,
                    color: const Color(0xFFE5E7EB),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Labels
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      origin,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      destination,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),

              // GPS coordinates
              if (busPosition != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Bus Location',
                      style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      busPosition!.latitude.toStringAsFixed(4),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      busPosition!.longitude.toStringAsFixed(4),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Schedule & ETA Section
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFF3F4F6), height: 1),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Scheduled Schedule',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF4B5563)),
                      const SizedBox(width: 4),
                      Text(
                        '${scheduledDeparture != null ? _formatTime(scheduledDeparture!) : '—'} → ${scheduledArrival != null ? _formatTime(scheduledArrival!) : '—'}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Estimated Arrival',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (totalDelay > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Text(
                            '+$totalDelay min',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      Text(
                        estimatedArrival ?? '—',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: totalDelay > 0 ? const Color(0xFFDC2626) : const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Update notice
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  tripStatus == 'in_progress'
                      ? Icons.sync_rounded
                      : Icons.info_outline_rounded,
                  size: 14,
                  color: const Color(0xFF6B7280),
                ),
                const SizedBox(width: 6),
                Text(
                  tripStatus == 'in_progress'
                      ? 'Location updates every 5 seconds'
                      : 'Tracking starts when driver departs',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Incident Alert Banner ───────────────────────────────────────────────────

class _IncidentAlertBanner extends StatefulWidget {
  final List<Map<String, dynamic>> incidents;
  const _IncidentAlertBanner({required this.incidents});

  @override
  State<_IncidentAlertBanner> createState() => _IncidentAlertBannerState();
}

class _IncidentAlertBannerState extends State<_IncidentAlertBanner> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.incidents.isEmpty) return const SizedBox();

    final latest = widget.incidents.first;
    final type = latest['type'] as String? ?? 'other';
    final desc = latest['description'] as String? ?? '';
    final createdAt = latest['created_at'] as String? ?? '';

    // Color configurations
    final colorConfigs = {
      'delay': [const Color(0xFFD97706), const Color(0xFFFEF3C7), Icons.timer_off_rounded],
      'breakdown': [const Color(0xFFDC2626), const Color(0xFFFEE2E2), Icons.build_rounded],
      'accident': [const Color(0xFFB91C1C), const Color(0xFFFEE2E2), Icons.car_crash_rounded],
      'other': [const Color(0xFF4B5563), const Color(0xFFF3F4F6), Icons.warning_amber_rounded],
    };

    final config = colorConfigs[type] ?? colorConfigs['other']!;
    final primaryColor = config[0] as Color;
    final bgColor = config[1] as Color;
    final icon = config[2] as IconData;

    return GestureDetector(
      onTap: () {
        if (widget.incidents.length > 1) {
          setState(() => _isExpanded = !_isExpanded);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primaryColor.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pulsing Icon
                _PulsingIcon(icon: icon, color: primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${type[0].toUpperCase()}${type.substring(1)} Reported',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                            ),
                          ),
                          Text(
                            _formatTimestamp(createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: primaryColor.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF374151),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.incidents.length > 1)
                  Icon(
                    _isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: primaryColor,
                    size: 20,
                  ),
              ],
            ),
            if (_isExpanded && widget.incidents.length > 1) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(color: Color(0x1F000000), height: 1),
              ),
              ...widget.incidents.skip(1).map((inc) {
                final iType = inc['type'] as String? ?? 'other';
                final iDesc = inc['description'] as String? ?? '';
                final iTime = inc['created_at'] as String? ?? '';
                final iConfig = colorConfigs[iType] ?? colorConfigs['other']!;
                final iColor = iConfig[0] as Color;
                final iIcon = iConfig[2] as IconData;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(iIcon, size: 16, color: iColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${iType[0].toUpperCase()}${iType.substring(1)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: iColor,
                                  ),
                                ),
                                Text(
                                  _formatTimestamp(iTime),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              iDesc,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4B5563),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(String ts) {
    if (ts.isEmpty) return '';
    try {
      final dt = DateTime.parse(ts).toLocal();
      final h = dt.hour;
      final period = h >= 12 ? 'PM' : 'AM';
      final dh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      return '$dh:${dt.minute.toString().padLeft(2, '0')} $period';
    } catch (_) {
      return '';
    }
  }
}

// ─── Pulsing Icon ────────────────────────────────────────────────────────────

class _PulsingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  const _PulsingIcon({required this.icon, required this.color});

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.85, end: 1.15).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, child) => Transform.scale(
        scale: _animation.value,
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: widget.color.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          widget.icon,
          color: widget.color,
          size: 20,
        ),
      ),
    );
  }
}

// ─── Locating Bus Chip ───────────────────────────────────────────────────────

class _LocatingBusChip extends StatefulWidget {
  const _LocatingBusChip();

  @override
  State<_LocatingBusChip> createState() => _LocatingBusChipState();
}

class _LocatingBusChipState extends State<_LocatingBusChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A73E8),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A73E8).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Locating bus...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
