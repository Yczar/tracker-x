import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:tracker_x/enums/map_style.dart';
import 'package:tracker_x/.env.dart';

class BaseTileLayer extends StatelessWidget {
  final MapStyle style;
  final String? apiKey;
  final int tileBuffer;
  final Color fallbackBackgroundColor;

  const BaseTileLayer({
    super.key,
    this.style = MapStyle.openStreetMap,
    this.apiKey,
    this.tileBuffer = 2,
    this.fallbackBackgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      urlTemplate: _getUrlTemplate(),
      additionalOptions: _getAdditionalOptions(),
      tileBuilder: (context, child, tile) {
        return DecoratedBox(
          decoration: BoxDecoration(color: fallbackBackgroundColor),
          child: child,
        );
      },
      tileProvider: NetworkTileProvider(),
    );
  }

  String _getUrlTemplate() {
    switch (style) {
      case MapStyle.dark:
        return 'https://api.mapbox.com/styles/v1/mapbox/dark-v10/tiles/{z}/{x}/{y}?access_token={accessToken}';
      case MapStyle.light:
        return 'https://api.mapbox.com/styles/v1/mapbox/light-v10/tiles/{z}/{x}/{y}?access_token={accessToken}';
      case MapStyle.satellite:
        return 'https://api.mapbox.com/styles/v1/mapbox/satellite-v9/tiles/{z}/{x}/{y}?access_token={accessToken}';
      case MapStyle.streets:
        return 'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token={accessToken}';
      case MapStyle.outdoors:
        return 'https://api.mapbox.com/styles/v1/mapbox/outdoors-v11/tiles/{z}/{x}/{y}?access_token={accessToken}';
      case MapStyle.custom:
        return 'https://api.mapbox.com/styles/v1/cizukanne/cjo4ibs854bzr2smk4m61hh0o/tiles/{z}/{x}/{y}?access_token={accessToken}';
      case MapStyle.openStreetMap:
        return 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
      case MapStyle.cartoLight:
        return 'https://cartodb-basemaps-a.global.ssl.fastly.net/light_all/{z}/{x}/{y}{r}.png';
      case MapStyle.cartoDark:
        return 'https://cartodb-basemaps-a.global.ssl.fastly.net/dark_all/{z}/{x}/{y}{r}.png';
      case MapStyle.stamenToner:
        return 'https://stamen-tiles.a.ssl.fastly.net/toner/{z}/{x}/{y}.png';
      case MapStyle.stamenWatercolor:
        return 'https://stamen-tiles.a.ssl.fastly.net/watercolor/{z}/{x}/{y}.jpg';
      case MapStyle.thunderforestTransport:
        return 'https://tile.thunderforest.com/transport/{z}/{x}/{y}.png?apikey={apiKey}';
      case MapStyle.esriWorldImagery:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
    }
  }

  Map<String, String> _getAdditionalOptions() {
    if (style == MapStyle.openStreetMap) {
      return {};
    }

    return {'accessToken': apiKey ?? environment['mapboxPublicKey']};
  }
}
