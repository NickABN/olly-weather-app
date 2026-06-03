import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:weather_app/features/auth/data/auth_repository_provider.dart';
import 'package:weather_app/shared/widgets/error_view.dart';
import 'package:weather_app/shared/widgets/loading_indicator.dart';
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
    Future.microtask(
      () => ref.read(weatherControllerProvider.notifier).refresh(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weatherState = ref.watch(weatherControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(weatherControllerProvider.notifier).refresh(),
        child: weatherState.when(
          loading: () => const LoadingIndicator(),
          error: (e, _) => _buildError(e.toString()),
          data: (weather) => weather == null
              ? _buildError('Could not load weather data')
              : _buildWeather(weather),
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    final clean = message.replaceFirst('Exception: ', '');
    final isPermission = clean.contains('permission');
    return ErrorView(
      message: isPermission
          ? 'Location permission denied.\nPlease enable location access and try again.'
          : clean,
      onRetry: () => ref.read(weatherControllerProvider.notifier).refresh(),
    );
  }

  Widget _buildWeather(Weather weather) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 16),
        Center(
          child: Text(
            weather.icon,
            style: const TextStyle(fontSize: 80),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            weather.description,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: 32),
        _WeatherTile(
          icon: Icons.thermostat,
          label: 'Temperature',
          value: '${weather.temperature.toStringAsFixed(1)}°C',
        ),
        _WeatherTile(
          icon: Icons.water_drop,
          label: 'Humidity',
          value: '${weather.humidity.toStringAsFixed(0)}%',
        ),
        _WeatherTile(
          icon: Icons.air,
          label: 'Wind Speed',
          value: '${weather.windSpeed.toStringAsFixed(1)} km/h',
        ),
        const SizedBox(height: 32),
        Center(
          child: Text(
            'Weather data: Open-Meteo (CC BY 4.0)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _WeatherTile extends StatelessWidget {
  const _WeatherTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(
        value,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
