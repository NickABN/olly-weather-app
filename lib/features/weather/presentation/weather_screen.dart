import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:weather_app/features/auth/data/auth_repository_provider.dart';
import 'package:weather_app/shared/widgets/error_view.dart';
import 'package:weather_app/features/weather/data/weather_model.dart';
import 'package:weather_app/features/weather/presentation/weather_controller.dart';

class WeatherScreen extends ConsumerStatefulWidget {
  const WeatherScreen({super.key});

  @override
  ConsumerState<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends ConsumerState<WeatherScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(weatherControllerProvider.notifier).refresh(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weatherState = ref.watch(weatherControllerProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(weatherControllerProvider.notifier).refresh(),
        child: weatherState.when(
          loading: () => const _WeatherSkeleton(),
          error: (e, _) => _buildError(e.toString()),
          data: (weather) => weather == null
              ? const _WeatherSkeleton()
              : _WeatherContent(weather: weather),
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    final clean = message.replaceFirst('Exception: ', '');
    final isLocationError = clean.contains('Location unavailable');
    return ErrorView(
      message: isLocationError
          ? 'Location access required. Grant permission to get local weather.'
          : clean,
      onRetry: isLocationError
          ? () => ref
              .read(weatherControllerProvider.notifier)
              .requestPermissionAndRefresh()
          : () => ref.read(weatherControllerProvider.notifier).refresh(),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _WeatherSkeleton extends StatelessWidget {
  const _WeatherSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _SkeletonBox(
          height: 240,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(child: _SkeletonBox(height: 80)),
              const SizedBox(width: 8),
              Expanded(child: _SkeletonBox(height: 80)),
              const SizedBox(width: 8),
              Expanded(child: _SkeletonBox(height: 80)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(child: _SkeletonBox(height: 120)),
              const SizedBox(width: 12),
              Expanded(child: _SkeletonBox(height: 120)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _SkeletonBox(height: 130),
        ),
      ],
    );
  }
}

class _SkeletonBox extends StatefulWidget {
  const _SkeletonBox({required this.height, this.borderRadius});

  final double height;
  final BorderRadius? borderRadius;

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.25, end: 0.55).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, child) => Opacity(opacity: _opacity.value, child: child),
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius:
              widget.borderRadius ?? BorderRadius.circular(16),
        ),
      ),
    );
  }
}

// ── Content ───────────────────────────────────────────────────────────────────

class _WeatherContent extends ConsumerWidget {
  const _WeatherContent({required this.weather});

  final Weather weather;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _HeroCard(
          weather: weather,
          onLogout: () async {
            await ref.read(authRepositoryProvider).signOut();
            if (context.mounted) context.go('/login');
          },
        ),
        if (weather.isApproximateLocation)
          const _ApproximateLocationBanner(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: _DetailRow(weather: weather),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(child: _UvIndexCard(uvIndex: weather.uvIndexMax)),
              const SizedBox(width: 12),
              Expanded(child: _AqiCard(aqi: weather.aqi)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _TodayForecastCard(items: weather.hourlyForecast),
        ),
        const SizedBox(height: 24),
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Weather data: Open-Meteo (CC BY 4.0)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                  ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Approximate location banner ───────────────────────────────────────────────

class _ApproximateLocationBanner extends ConsumerWidget {
  const _ApproximateLocationBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cs.tertiary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cs.tertiary.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.location_searching, color: cs.tertiary, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Approximate location · Enable GPS for better accuracy',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ),
            const SizedBox(width: 4),
            TextButton(
              onPressed: () => ref
                  .read(weatherControllerProvider.notifier)
                  .requestPermissionAndRefresh(),
              style: TextButton.styleFrom(
                foregroundColor: cs.tertiary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Enable GPS',
                style: tt.labelSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero card ─────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.weather, required this.onLogout});

  final Weather weather;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return SizedBox(
      height: 240,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [
                    Color(0xFF0D2010),
                    Color(0xFF1A3A1A),
                    Color(0xFF2D5A2D),
                  ],
                ),
              ),
              child: Opacity(
                opacity: 0.35,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0.6, -0.7),
                      radius: 0.8,
                      colors: [
                        Color(0xFFD4A853),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          weather.cityName ?? 'My Location',
                          style: tt.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              weather.region ?? 'Current location',
                              style: tt.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          weather.icon,
                          style: const TextStyle(fontSize: 52),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${weather.temperature.toStringAsFixed(0)}°C',
                          style: tt.displayMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          weather.description,
                          style: tt.titleMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white70),
                      onPressed: onLogout,
                      tooltip: 'Sign out',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Detail chips ──────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.weather});

  final Weather weather;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DetailChip(
            icon: Icons.air,
            label: 'Wind',
            value: '${weather.windSpeed.toStringAsFixed(1)} km/h',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _DetailChip(
            icon: Icons.water_drop_outlined,
            label: 'Humidity',
            value: '${weather.humidity.toStringAsFixed(0)}%',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _DetailChip(
            icon: Icons.umbrella_outlined,
            label: 'Rain',
            value: '${weather.precipitation.toStringAsFixed(1)} mm',
          ),
        ),
      ],
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, size: 22, color: cs.secondary),
            const SizedBox(height: 6),
            Text(
              value,
              style: tt.titleSmall?.copyWith(color: cs.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Forecast card ─────────────────────────────────────────────────────────────

class _TodayForecastCard extends StatelessWidget {
  const _TodayForecastCard({required this.items});

  final List<HourlyForecast> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule_outlined, size: 16, color: cs.secondary),
                const SizedBox(width: 6),
                Text("Today's Forecast", style: tt.titleSmall),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final item = items[i];
                  final isNow = i == 0 ||
                      (item.time.hour == now.hour &&
                          item.time.day == now.day);
                  return _HourlyItem(item: item, isNow: isNow && i == 0);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HourlyItem extends StatelessWidget {
  const _HourlyItem({required this.item, required this.isNow});

  final HourlyForecast item;
  final bool isNow;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final label = isNow
        ? 'Now'
        : '${item.time.hour.toString().padLeft(2, '0')}:00';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: tt.labelSmall?.copyWith(
            color: isNow
                ? cs.secondary
                : cs.onSurface.withValues(alpha: 0.6),
            fontWeight: isNow ? FontWeight.w600 : null,
          ),
        ),
        const SizedBox(height: 6),
        Text(item.icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 6),
        Text(
          '${item.temperature.toStringAsFixed(0)}°',
          style: tt.titleSmall?.copyWith(color: cs.onSurface),
        ),
      ],
    );
  }
}

// ── UV + AQI cards ────────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _UvIndexCard extends StatelessWidget {
  const _UvIndexCard({required this.uvIndex});

  final double uvIndex;

  String get _category {
    if (uvIndex <= 2) return 'Low';
    if (uvIndex <= 5) return 'Moderate';
    if (uvIndex <= 7) return 'High';
    if (uvIndex <= 10) return 'Very High';
    return 'Extreme';
  }

  String? get _sunProtectionHint {
    if (uvIndex <= 2) return null;
    if (uvIndex <= 5) return 'Use sun protection until ~2 PM';
    return 'Use sun protection until ~4 PM';
  }

  Color _badgeColor(ColorScheme cs) {
    if (uvIndex <= 2) return cs.secondary;
    if (uvIndex <= 5) return cs.tertiary;
    return cs.error;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wb_sunny_outlined, size: 16, color: cs.tertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('UV Index', style: tt.labelMedium),
                ),
                _CategoryBadge(
                  label: _category,
                  color: _badgeColor(cs),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              uvIndex.toStringAsFixed(0),
              style: tt.headlineMedium?.copyWith(color: cs.onSurface),
            ),
            if (_sunProtectionHint != null) ...[
              const SizedBox(height: 6),
              Text(
                _sunProtectionHint!,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AqiCard extends StatelessWidget {
  const _AqiCard({required this.aqi});

  final int aqi;

  String get _category {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy*';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  Color _badgeColor(ColorScheme cs) {
    if (aqi <= 50) return cs.secondary;
    if (aqi <= 100) return cs.tertiary;
    return cs.error;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final badgeColor = _badgeColor(cs);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.air_outlined, size: 16, color: cs.secondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('Air Quality', style: tt.labelMedium),
                ),
                if (aqi > 0)
                  _CategoryBadge(label: _category, color: badgeColor),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              aqi > 0 ? '$aqi AQI' : '—',
              style: tt.headlineMedium?.copyWith(color: cs.onSurface),
            ),
            if (aqi > 0) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: (aqi / 300).clamp(0.0, 1.0),
                  backgroundColor: badgeColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
                  minHeight: 6,
                ),
              ),
            ] else
              Text(
                'Unavailable',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
