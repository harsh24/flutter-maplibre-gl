// import 'dart:developer';

import 'dart:developer';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';
import 'package:maplibre_gl/mapbox_gl.dart';

import 'offline_region_map.dart';
import 'page.dart';

final LatLngBounds hawaiiBounds = LatLngBounds(
  southwest: const LatLng(-33.684204, 150.138734),
  northeast: const LatLng(-33.577643, 150.311415),
);

final LatLngBounds santiagoBounds = LatLngBounds(
  southwest: const LatLng(-33.686037, 150.25107),
  northeast: const LatLng(-33.579478, 150.423753),
);

final LatLngBounds aucklandBounds = LatLngBounds(
  southwest: const LatLng(-33.935670, 151.177711),
  northeast: const LatLng(-33.880107, 151.266975),
);

final List<OfflineRegionDefinition> regionDefinitions = [
  OfflineRegionDefinition(
    bounds: hawaiiBounds,
    minZoom: 13.0,
    maxZoom: 14.0,
    mapStyleUrl:
        "https://cdn.shopify.com/s/files/1/0577/6159/5426/files/bushwalk.json?v=1686989331",

    // "https://api.maptiler.com/maps/outdoor-v2/style.json?key=Gt6v5tQ3MeLWu972Z755",
  ),
  OfflineRegionDefinition(
    bounds: santiagoBounds,
    minZoom: 13.0,
    maxZoom: 14.0,
    mapStyleUrl:
        "https://cdn.shopify.com/s/files/1/0577/6159/5426/files/bushwalk.json?v=1686989331",
    // "https://api.maptiler.com/maps/outdoor-v2/style.json?key=Gt6v5tQ3MeLWu972Z755",
  ),
  OfflineRegionDefinition(
    bounds: aucklandBounds,
    minZoom: 12.0,
    maxZoom: 16.0,
    mapStyleUrl:
        "https://cdn.shopify.com/s/files/1/0577/6159/5426/files/bushwalk.json?v=1686989331",

    // "https://api.maptiler.com/maps/outdoor-v2/style.json?key=Gt6v5tQ3MeLWu972Z755",
  ),
];

final List<String> regionNames = ['Hawaii', 'Santiago', 'Auckland'];

class OfflineRegionListItem {
  OfflineRegionListItem({
    required this.offlineRegionDefinition,
    required this.downloadedId,
    required this.isDownloading,
    required this.name,
    required this.estimatedTiles,
  });

  final OfflineRegionDefinition offlineRegionDefinition;
  final int? downloadedId;
  final bool isDownloading;
  final String name;
  final int estimatedTiles;

  OfflineRegionListItem copyWith({
    int? downloadedId,
    bool? isDownloading,
  }) =>
      OfflineRegionListItem(
        offlineRegionDefinition: offlineRegionDefinition,
        name: name,
        estimatedTiles: estimatedTiles,
        downloadedId: downloadedId,
        isDownloading: isDownloading ?? this.isDownloading,
      );

  bool get isDownloaded => downloadedId != null;
}

final List<OfflineRegionListItem> allRegions = [
  OfflineRegionListItem(
    offlineRegionDefinition: regionDefinitions[0],
    downloadedId: null,
    isDownloading: false,
    name: regionNames[0],
    estimatedTiles: 61,
  ),
  OfflineRegionListItem(
    offlineRegionDefinition: regionDefinitions[1],
    downloadedId: null,
    isDownloading: false,
    name: regionNames[1],
    estimatedTiles: 3580,
  ),
  OfflineRegionListItem(
    offlineRegionDefinition: regionDefinitions[2],
    downloadedId: null,
    isDownloading: false,
    name: regionNames[2],
    estimatedTiles: 202,
  ),
];

class OfflineRegionsPage extends ExamplePage {
  OfflineRegionsPage() : super(const Icon(Icons.map), 'Offline Regions');

  @override
  Widget build(BuildContext context) {
    return const OfflineRegionBody();
  }
}

class OfflineRegionBody extends StatefulWidget {
  const OfflineRegionBody();

  @override
  _OfflineRegionsBodyState createState() => _OfflineRegionsBodyState();
}

class _OfflineRegionsBodyState extends State<OfflineRegionBody> {
  List<OfflineRegionListItem> _items = [];

  @override
  void initState() {
    super.initState();
    clearAmbientCache();
    _updateListOfRegions();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          itemCount: _items.length,
          itemBuilder: (context, index) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.map),
                onPressed: () => _goToMap(_items[index]),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _items[index].name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'Est. tiles: ${_items[index].estimatedTiles}',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _items[index].isDownloading
                  ? Container(
                      child: CircularProgressIndicator(),
                      height: 16,
                      width: 16,
                    )
                  : IconButton(
                      icon: Icon(
                        _items[index].isDownloaded
                            ? Icons.delete
                            : Icons.file_download,
                      ),
                      onPressed: _items[index].isDownloaded
                          ? () => _deleteRegion(_items[index], index)
                          : () => _downloadRegion(_items[index], index),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  void _updateListOfRegions() async {
    List<OfflineRegion> offlineRegions = await getListOfRegions();
    List<OfflineRegionListItem> regionItems = [];
    for (var item in allRegions) {
      final offlineRegion = offlineRegions.firstWhereOrNull(
          (offlineRegion) => offlineRegion.metadata['name'] == item.name);
      if (offlineRegion != null) {
        regionItems.add(item.copyWith(downloadedId: offlineRegion.id));
      } else {
        regionItems.add(item);
      }
    }
    setState(() {
      _items.clear();
      _items.addAll(regionItems);
    });
  }

  void _downloadRegion(OfflineRegionListItem item, int index) async {
    setState(() {
      _items.removeAt(index);
      _items.insert(index, item.copyWith(isDownloading: true));
    });

    try {
      final downloadingRegion = await downloadOfflineRegion(
        item.offlineRegionDefinition,
        metadata: {
          'name': regionNames[index],
        },
      );
      setState(() {
        _items.removeAt(index);
        _items.insert(
            index,
            item.copyWith(
              isDownloading: false,
              downloadedId: downloadingRegion.id,
            ));
      });
    } on Exception catch (_) {
      setState(() {
        _items.removeAt(index);
        _items.insert(
            index,
            item.copyWith(
              isDownloading: false,
              downloadedId: null,
            ));
      });
      return;
    }
  }

  void _deleteRegion(OfflineRegionListItem item, int index) async {
    setState(() {
      _items.removeAt(index);
      _items.insert(index, item.copyWith(isDownloading: true));
    });

    await deleteOfflineRegion(
      item.downloadedId!,
    );

    setState(() {
      _items.removeAt(index);
      _items.insert(
          index,
          item.copyWith(
            isDownloading: false,
            downloadedId: null,
          ));
    });
  }

  _goToMap(OfflineRegionListItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OfflineRegionMap(item),
      ),
    );
  }
}
