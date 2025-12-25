import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../constants/external_urls.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../dashboard/presentation/widgets/nebula_background.dart';
import 'providers/settings_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool redMode = ref.watch(settingsNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF020204),
      body: Stack(
        children: <Widget>[
          const NebulaBackground(),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[Colors.transparent, Colors.white],
                        stops: <double>[0, 0.05], // Soft fade at the top
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: ListView(
                      padding: EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 20,
                        bottom: 70 + MediaQuery.of(context).padding.bottom + 20,
                      ),
                      children: <Widget>[
                        // Red Mode Card
                        GlassPanel(
                          enableBlur: false,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Row(
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.remove_red_eye, color: Colors.white),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    const Text(
                                      'Red Mode',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Preserve night vision',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: redMode,
                                onChanged: (bool value) {
                                  ref.read(settingsNotifierProvider.notifier).toggleRedMode();
                                },
                                activeThumbColor: Colors.redAccent,
                                activeTrackColor: Colors.redAccent.withOpacity(0.3),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),

                        // Locations Card
                        GlassPanel(
                          enableBlur: false,
                          onTap: () => context.push('/settings/locations'),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          child: Row(
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Ionicons.location, color: Colors.white),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Text(
                                  'Locations',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Support Astr Card - AC#7: Updated to Ko-fi
                        GlassPanel(
                          enableBlur: false,
                          onTap: () async {
                            final Uri url = Uri.parse(ExternalUrls.kofiSupport);
                            if (!await launchUrl(url)) {
                              // Handle error silently or show snackbar
                            }
                          },
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Row(
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.pink.withOpacity(0.1), // Ko-fi brand color
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Ionicons.heart, color: Colors.pink), // Ko-fi uses heart
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    const Text(
                                      'Support Astr',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Hi! I'm a solo designer working on this. Your support helps me to push this project further!",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
