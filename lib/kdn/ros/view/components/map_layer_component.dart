import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:vms_app/kdn/main/model/VesselSearchModel.dart';
import 'package:vms_app/kdn/ros/view/mainView.dart';
import 'package:vms_app/kdn/ros/viewModel/RouteSearchViewModel.dart';

/// 지도 레이어 컴포넌트 - FlutterMap과 관련된 모든 레이어 관리
class MapLayerComponent extends StatelessWidget {
  final MapControllerProvider mapControllerProvider;
  final RouteSearchViewModel routeSearchViewModel;
  final List<VesselSearchModel> vessels;
  final LatLng? currentPosition;
  final bool isTrackingEnabled;
  final bool isOtherVesselsVisible;
  final int? userMmsi;
  final Function(VesselSearchModel) onVesselTap;

  const MapLayerComponent({
    Key? key,
    required this.mapControllerProvider,
    required this.routeSearchViewModel,
    required this.vessels,
    this.currentPosition,
    required this.isTrackingEnabled,
    required this.isOtherVesselsVisible,
    this.userMmsi,
    required this.onVesselTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<RouteSearchViewModel>(
      builder: (context, routeSearchViewModel, child) {
        final mapController = Provider.of<MapControllerProvider>(context).mapController;

        // 과거 항적 처리
        int cnt = 20;
        if (routeSearchViewModel.pastRoutes.length <= cnt) cnt = 1;

        var pastRouteLine = <LatLng>[];
        if (routeSearchViewModel.pastRoutes.isNotEmpty) {
          final firstPoint = routeSearchViewModel.pastRoutes.first;
          pastRouteLine.add(LatLng(firstPoint.lttd ?? 0, firstPoint.lntd ?? 0));

          if (routeSearchViewModel.pastRoutes.length > 2) {
            for (int i = 1; i < routeSearchViewModel.pastRoutes.length - 1; i++) {
              if (i % cnt == 0) {
                final route = routeSearchViewModel.pastRoutes[i];
                pastRouteLine.add(LatLng(route.lttd ?? 0, route.lntd ?? 0));
              }
            }
          }

          final lastPoint = routeSearchViewModel.pastRoutes.last;
          pastRouteLine.add(LatLng(lastPoint.lttd ?? 0, lastPoint.lntd ?? 0));
        }

        // 예측 항로 처리
        var predRouteLine = <LatLng>[];
        predRouteLine.addAll(
            routeSearchViewModel.predRoutes
                .map((route) => LatLng(route.lttd ?? 0, route.lntd ?? 0))
        );

        if (predRouteLine.isNotEmpty && pastRouteLine.isNotEmpty) {
          pastRouteLine.add(predRouteLine.first);
        }

        // 항적 표시 조건 확인
        if (!isTrackingEnabled && !routeSearchViewModel.isNavigationHistoryMode) {
          pastRouteLine.clear();
          predRouteLine.clear();
        }

        return FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: currentPosition ?? LatLng(35.374509, 126.132268),
            initialZoom: 12.0,
            maxZoom: 14.0,
            minZoom: 5.5,
            interactionOptions: InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            // 전자해도 레이어
            _buildElectronicChartLayer(),

            // 터빈 레이어
            _buildTurbineLayer(),

            // 과거 항적 레이어
            _buildPastRouteLayer(pastRouteLine),

            // 예측 항로 레이어
            _buildPredictedRouteLayer(predRouteLine),

            // 퇴각 항로 레이어
            _buildEscapeRouteLayer(vessels),

            // 선박 레이어
            _buildVesselLayer(vessels, userMmsi),
          ],
        );
      },
    );
  }

  /// 전자해도 레이어 빌드
  Widget _buildElectronicChartLayer() {
    return Stack(
      children: [
        TileLayer(
          wmsOptions: WMSTileLayerOptions(
            baseUrl: "${dotenv.env['GEOSERVER_URL']}?",
            layers: ['vms_space:enc_map'],
            format: 'image/png',
            transparent: true,
            version: '1.1.1',
          ),
        ),
        TileLayer(
          wmsOptions: WMSTileLayerOptions(
            baseUrl: "${dotenv.env['GEOSERVER_URL']}?",
            layers: ['vms_space:t_enc_sou_sp01'],
            format: 'image/png',
            transparent: true,
            version: '1.1.1',
          ),
        ),
      ],
    );
  }

  /// 터빈 레이어 빌드
  Widget _buildTurbineLayer() {
    return TileLayer(
      wmsOptions: WMSTileLayerOptions(
        baseUrl: "${dotenv.env['GEOSERVER_URL']}?",
        layers: ['vms_space:t_gis_tur_sp01'],
        format: 'image/png',
        transparent: true,
        version: '1.1.1',
      ),
    );
  }

  /// 과거 항적 레이어 빌드
  Widget _buildPastRouteLayer(List<LatLng> pastRouteLine) {
    return Stack(
      children: [
        // 선 레이어
        PolylineLayer(
          polylines: [
            if (pastRouteLine.isNotEmpty)
              Polyline(
                points: pastRouteLine,
                strokeWidth: 1.0,
                color: Colors.orange,
              ),
          ],
        ),
        // 포인트 레이어
        MarkerLayer(
          markers: pastRouteLine.asMap().entries.map((entry) {
            int index = entry.key;
            LatLng point = entry.value;

            if (index == 0) {
              return Marker(
                point: point,
                width: 10,
                height: 10,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                ),
              );
            } else {
              return Marker(
                point: point,
                width: 4,
                height: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 0.5),
                  ),
                ),
              );
            }
          }).toList(),
        ),
      ],
    );
  }

  /// 예측 항로 레이어 빌드
  Widget _buildPredictedRouteLayer(List<LatLng> predRouteLine) {
    return Stack(
      children: [
        // 선 레이어
        PolylineLayer(
          polylines: [
            if (predRouteLine.isNotEmpty)
              Polyline(
                points: predRouteLine,
                strokeWidth: 1.0,
                color: Colors.red,
              ),
          ],
        ),
        // 포인트 레이어
        MarkerLayer(
          markers: predRouteLine.map((point) {
            return Marker(
              point: point,
              width: 4,
              height: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 0.5),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 퇴각 항로 레이어 빌드
  Widget _buildEscapeRouteLayer(List<VesselSearchModel> vessels) {
    return Stack(
      children: [
        // 점선 경로
        PolylineLayer(
          polylineCulling: false,
          polylines: vessels
              .where((v) => v.escapeRouteGeojson != null)
              .map((v) {
            final pts = parseGeoJsonLineString(v.escapeRouteGeojson!);
            return Polyline(
              points: pts,
              strokeWidth: 2.0,
              color: Colors.black,
              isDotted: true,
            );
          }).toList(),
        ),
        // 끝점 삼각형
        PolygonLayer(
          polygons: vessels
              .where((v) => v.escapeRouteGeojson != null)
              .map((v) {
            final pts = parseGeoJsonLineString(v.escapeRouteGeojson!);
            if (pts.length < 2) return null;

            final end = pts.last;
            final prev = pts[pts.length - 2];

            final dx = end.longitude - prev.longitude;
            final dy = end.latitude - prev.latitude;
            final dist = sqrt(dx * dx + dy * dy);
            if (dist == 0) return null;

            final ux = dx / dist;
            final uy = dy / dist;
            final vx = -uy;
            final vy = ux;

            const double size = 0.0005;

            final apex = LatLng(
              end.latitude + uy * size,
              end.longitude + ux * size,
            );

            final baseCenter = LatLng(
              end.latitude - uy * (size * 0.5),
              end.longitude - ux * (size * 0.5),
            );

            final halfWidth = size / sqrt(3);

            final b1 = LatLng(
              baseCenter.latitude + vy * halfWidth,
              baseCenter.longitude + vx * halfWidth,
            );
            final b2 = LatLng(
              baseCenter.latitude - vy * halfWidth,
              baseCenter.longitude - vx * halfWidth,
            );

            return Polygon(
              points: [apex, b1, b2],
              color: Colors.black,
              borderColor: Colors.black,
              borderStrokeWidth: 1,
              isFilled: true,
            );
          })
              .where((poly) => poly != null)
              .cast<Polygon>()
              .toList(),
        ),
      ],
    );
  }

  /// 선박 레이어 빌드
  Widget _buildVesselLayer(List<VesselSearchModel> vessels, int? userMmsi) {
    return Stack(
      children: [
        // 내 선박
        MarkerLayer(
          markers: vessels
              .where((vessel) => vessel.mmsi == userMmsi)
              .map((vessel) {
            return Marker(
              point: LatLng(vessel.lttd ?? 0, vessel.lntd ?? 0),
              width: 25,
              height: 25,
              child: Transform.rotate(
                angle: (vessel.cog ?? 0) * (pi / 180),
                child: SvgPicture.asset(
                  'assets/kdn/home/img/myVessel.svg',
                  width: 40,
                  height: 40,
                ),
              ),
            );
          }).toList(),
        ),
        // 다른 선박들
        Opacity(
          opacity: isOtherVesselsVisible ? 1.0 : 0.0,
          child: IgnorePointer(
            ignoring: !isOtherVesselsVisible,
            child: MarkerLayer(
              markers: vessels
                  .where((vessel) => vessel.mmsi != userMmsi)
                  .map((vessel) {
                return Marker(
                  point: LatLng(vessel.lttd ?? 0, vessel.lntd ?? 0),
                  width: 25,
                  height: 25,
                  child: GestureDetector(
                    onTap: () => onVesselTap(vessel),
                    child: Transform.rotate(
                      angle: (vessel.cog ?? 0) * (pi / 180),
                      child: SvgPicture.asset(
                        'assets/kdn/home/img/otherVessel.svg',
                        width: 40,
                        height: 40,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

// GeoJSON 파싱 함수
List<LatLng> parseGeoJsonLineString(String geoJsonStr) {
  try {
    final decodedOnce = jsonDecode(geoJsonStr);
    final geoJson = decodedOnce is String ? jsonDecode(decodedOnce) : decodedOnce;
    final coords = geoJson['coordinates'] as List;
    return coords.map<LatLng>((c) {
      final lon = double.tryParse(c[0].toString());
      final lat = double.tryParse(c[1].toString());
      if (lat == null || lon == null) throw FormatException();
      return LatLng(lat, lon);
    }).toList();
  } catch (_) {
    return [];
  }
}