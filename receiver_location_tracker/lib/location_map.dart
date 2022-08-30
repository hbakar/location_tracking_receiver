import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class LocationMap extends StatefulWidget {
  LocationMap({Key? key}) : super(key: key);

  @override
  State<LocationMap> createState() => _LocationMapState();
}

class _LocationMapState extends State<LocationMap> {
  late IO.Socket socket;
  late Map<MarkerId, Marker> _markers;
  Completer<GoogleMapController> _controller = Completer();

  static const CameraPosition _cameraPosition = CameraPosition(
      target: LatLng(40.213072925107255, 28.944392105340924), zoom: 14);

  @override
  void initState() {
    super.initState();
    _markers = <MarkerId, Marker>{};
    _markers.clear();

    initSocket();
  }

  Future<void> initSocket() async {
    try {
      socket = IO.io("http://192.168.1.156:3700", <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
      });

      socket.connect();

      socket.on("position-change", (data) async {
        var latLng = jsonDecode(data);

        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
            target: LatLng(latLng["lat"], latLng["lng"]), zoom: 19)));

        var image = await BitmapDescriptor.fromAssetImage(
            ImageConfiguration(), "assets/marker.png");

        Marker marker1 = Marker(
            markerId: MarkerId("ID"),
            icon: image,
            position: LatLng(latLng["lat"], latLng["lng"]));

        setState(() {
          _markers[MarkerId("ID")] = marker1;
        });
      });
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        initialCameraPosition: _cameraPosition,
        mapType: MapType.normal,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        markers: Set<Marker>.of(_markers.values),
      ),
    );
  }
}
