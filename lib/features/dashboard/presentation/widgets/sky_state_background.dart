import 'package:flutter/material.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/engine/models/sky_state.dart';

class SkyStateBackground extends StatelessWidget {
  const SkyStateBackground({
    super.key,
    required this.skyState,
  });

  final SkyState skyState;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const ColoredBox(color: AppColors.surface),
        Image.asset(
          SkyStateAssets.pathFor(skyState),
          fit: BoxFit.cover,
          opacity: const AlwaysStoppedAnimation<double>(0.5),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0x33448AFF),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SkyStateAssets {
  const SkyStateAssets._();

  static String pathFor(SkyState state) {
    return switch (state) {
      SkyState.milkyWayVisible => 'assets/img/milky_way.jpg',
      SkyState.starrySkies => 'assets/img/starry_sky.jpg',
      SkyState.planetsVisible => 'assets/img/planets.jpg',
      SkyState.fewStars => 'assets/img/few_stars.jpg',
      SkyState.cloudy => 'assets/img/cloudy.jpg',
      SkyState.tooMuchLight => 'assets/img/excessive_light_pollution.jpg',
    };
  }
}
